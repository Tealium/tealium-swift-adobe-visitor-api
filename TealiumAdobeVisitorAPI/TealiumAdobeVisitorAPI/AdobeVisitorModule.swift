//
//  AdobeVisitorModule.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if COCOAPODS
import TealiumSwift
#else
import TealiumCore
#endif

public class TealiumAdobeVisitorModule: Collector {

    public var id = "TealiumAdobeVisitorModule"

    public var config: TealiumConfig

    var diskStorage: TealiumDiskStorageProtocol?

    public var data: [String: Any]? {
        get {
            if let ecID = visitor?.experienceCloudID {
                return [TealiumAdobeVisitorConstants.adobeEcid: ecID]
            } else {
                return nil
            }
        }
    }

    public var visitor: AdobeVisitor? {
        willSet {
            if newValue == nil {
                diskStorage?.delete(completion: nil)
            } else if newValue?.isEmpty == false {
                diskStorage?.save(newValue, completion: nil)
                delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.successMessage)
            }
        }
    }

    var visitorAPI: AdobeExperienceCloudIDService?

    var error: Error? {
        willSet {
            delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.failureMessage)
        }
    }

    var delegate: ModuleDelegate?
    var retryManager: Retryable

    public required convenience init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage, adobeVisitorAPI: nil, completion: completion)
    }

    init(context: TealiumContext,
         delegate: ModuleDelegate?,
         diskStorage: TealiumDiskStorageProtocol?,
         retryManager: Retryable? = nil,
         adobeVisitorAPI: AdobeExperienceCloudIDService? = nil,
         completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {

        self.retryManager = retryManager ?? RetryManager(queue: TealiumQueues.backgroundSerialQueue, delay: Double.random(in: 10.0...30.0))
        self.config = context.config
        self.delegate = delegate
        guard let orgId = config.adobeVisitorOrgId else {
            completion((.failure(AdobeVisitorError.missingOrgID), [AdobeVisitorModuleKeys.error: AdobeVisitorModuleConstants.missingOrgId]))
            return
        }
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: self.id)
        visitorAPI = adobeVisitorAPI ?? AdobeVisitorAPI(adobeOrgId: orgId, enableCookies: false)
        if let existingId = config.adobeVisitorExistingEcid {
            self.visitor = AdobeVisitor(experienceCloudID: existingId, idSyncTTL: nil, dcsRegion: nil, blob: nil, nextRefresh: nil)
            self.visitorAPI?.visitor = visitor
            refreshECID(visitor: visitor)
        }
        if let ecID = getECIDFromDisk() {
            self.visitor = ecID
            self.visitorAPI?.visitor = visitor
            if let adobeCustomVisitorId = config.adobeVisitorCustomVisitorId, let dataProviderId = config.adobeVisitorDataProviderId {
                linkECIDToKnownIdentifier(adobeCustomVisitorId, dataProviderId: dataProviderId, authState: config.adobeVisitorAuthState)
            }
        } else {
            if let adobeCustomVisitorId = config.adobeVisitorCustomVisitorId, let dataProviderId = config.adobeVisitorDataProviderId {
                getAndLink(customVisitorId: adobeCustomVisitorId, dataProviderId: dataProviderId, authState: config.adobeVisitorAuthState)
            } else {
                getECID()
            }
        }
    }

    /// - Returns: Optional `AdobeVisitor` instance
    func getECIDFromDisk() -> AdobeVisitor? {
        if let ecID = diskStorage?.retrieve(as: AdobeVisitor.self), !ecID.isEmpty {
            delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.successMessage)
            if let nextRefresh = ecID.nextRefresh, Date() >= nextRefresh || ecID.nextRefresh == nil {
                refreshECID(visitor: ecID)
            }
            return ecID
        }
        return nil
    }

    /// Retrieves a new ECID from the Adobe Visitor API
    /// - Parameters:
    ///    - retries: `Int` Current number of retries
    ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
    ///     - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
    func getECID(retries: Int = 0,
                 completion: AdobeVisitorCompletion? = nil) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECID { result in
            switch result {
            case .success(let visitor):
                self.visitor = visitor
                completion?(.success(visitor))
            case .failure(let error):
                if retries < self.config.adobeVisitorRetries {
                    self.retryManager.submit {
                        self.getECID(retries: retries + 1, completion: completion)
                    }
                } else {
                    self.error = error
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this user identifier
    ///     - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
    ///     - retries: `Int?` the current number of retries
    func getAndLink(customVisitorId: String,
                    dataProviderId: String,
                    authState: AdobeVisitorAuthState?,
                    retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECIDAndLink(customVisitorId: customVisitorId, dataProviderId: dataProviderId, authState: authState) { result in
            switch result {
            case .success(let ecID):
                self.visitor = ecID
            case .failure(let error):
                if retries < self.config.adobeVisitorRetries {
                    self.retryManager.submit {
                        self.getAndLink(customVisitorId: customVisitorId, dataProviderId: dataProviderId, authState: authState, retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this user identifier
    ///     - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
    ///     - retries: `Int?` the current number of retries
    func linkECIDToKnownIdentifier(_ customVisitorId: String,
                                   dataProviderId: String,
                                   authState: AdobeVisitorAuthState? = nil,
                                   retries: Int = 0,
                                   completion: AdobeVisitorCompletion? = nil) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        guard let experienceCloudId = self.visitor?.experienceCloudID else {
            getAndLink(customVisitorId: customVisitorId, dataProviderId: dataProviderId, authState: authState)
            return
        }

        visitorAPI.linkExistingECIDToKnownIdentifier(customVisitorId: customVisitorId, dataProviderID: dataProviderId, experienceCloudId: experienceCloudId, authState: config.adobeVisitorAuthState) { result in
            switch result {
            case .success(let visitor):
                self.visitor = visitor
                completion?(.success(visitor))
            case .failure(let error):
                if retries < self.config.adobeVisitorRetries {
                    self.retryManager.submit {
                        self.linkECIDToKnownIdentifier(customVisitorId, dataProviderId: dataProviderId, authState: authState, retries: retries + 1, completion: completion)
                    }
                } else {
                    self.error = error
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Sends a refresh request to the Adobe Visitor API. Used if the TTL has expired.
    /// - Parameters:
    ///     - visitor: `AdobeVisitor` containing the current ECID
    ///     - retries: `Int?` the current number of retries
    func refreshECID(retries: Int = 0,
                     visitor: AdobeVisitor?) {
        guard let visitorAPI = visitorAPI,
              let existingECID = visitor?.experienceCloudID else {
            return
        }
        visitorAPI.refreshECID(existingECID: existingECID) { result in
            switch result {
            case .success(let visitor):
                self.visitor = visitor
            case .failure(let error):
                if retries < self.config.adobeVisitorRetries {
                    self.retryManager.submit {
                        self.refreshECID(retries: retries + 1, visitor: visitor)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    /// Resets the Adobe Experience Cloud ID. A new ID will be requested immediately
    ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
    ///     - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
    func resetECID(completion: AdobeVisitorCompletion? = nil) {
        self.visitor = nil
        self.visitorAPI?.visitor = nil
        visitorAPI?.resetNetworkSession()
        getECID(completion: completion)
    }
}

extension TealiumAdobeVisitorModule: DispatchValidator {
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        guard let _ = config.adobeVisitorOrgId else {
            return (false, [AdobeVisitorModuleKeys.error: AdobeVisitorModuleConstants.missingOrgId])
        }
        if let error = error {
            return (false, [AdobeVisitorModuleKeys.error: "Unrecoverable error: \(error.localizedDescription)"])
        }
        guard let data = self.data else {
            return (true, [TealiumKey.queueReason: AdobeVisitorError.missingExperienceCloudID.localizedDescription])
        }
        return (false, data)
    }

    public func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }

    public func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }
}
