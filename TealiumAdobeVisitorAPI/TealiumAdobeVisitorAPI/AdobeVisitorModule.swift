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

    public let id = "TealiumAdobeVisitorModule"

    public var config: TealiumConfig
    let context: TealiumContext
    var diskStorage: TealiumDiskStorageProtocol?
    let visitorAPI: AdobeExperienceCloudIDService?
    public var data: [String: Any]? {
        get {
            if let ecID = visitor?.experienceCloudID {
                return [TealiumDataKey.adobeEcid: ecID]
            } else {
                return nil
            }
        }
    }

    private var onECIDUpdate = TealiumReplaySubject<String?>()
    public var visitor: AdobeVisitor? { // Always changed from the TealiumQueues.backgroundSerialQueue
        willSet {
            visitorAPI?.visitor = newValue
            if let newValue = newValue {
                diskStorage?.save(newValue, completion: nil)
                delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.successMessage)
            } else {
                diskStorage?.delete(completion: nil)
            }
            if let ecid = newValue?.experienceCloudID, ecid != onECIDUpdate.last() {
                onECIDUpdate.publish(ecid)
            }
        }
    }

    var error: Error? {
        willSet {
            if let _ = error {
                if visitor == nil {
                    onECIDUpdate.publish(nil)
                }
                delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.failureMessage)
            }
        }
    }

    var delegate: ModuleDelegate?

    public required convenience init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage, adobeVisitorAPI: nil, completion: completion)
    }

    init(context: TealiumContext,
         delegate: ModuleDelegate?,
         diskStorage: TealiumDiskStorageProtocol?,
         adobeVisitorAPI: AdobeExperienceCloudIDService? = nil,
         completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {

        self.context = context
        self.config = context.config
        self.delegate = delegate
        guard let orgId = config.adobeVisitorOrgId else {
            visitorAPI = nil
            completion((.failure(AdobeVisitorError.missingOrgID), [AdobeVisitorModuleKeys.error: AdobeVisitorModuleConstants.missingOrgId]))
            return
        }
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: self.id)
        self.visitorAPI = adobeVisitorAPI ?? AdobeVisitorAPI(retryManager: RetryManager(queue: TealiumQueues.backgroundSerialQueue,
                                                                                        delay: Double.random(in: 10.0...30.0),
                                                                                        maxRetries: config.adobeVisitorRetries),
                                                             adobeOrgId: orgId,
                                                             enableCookies: false)
        initializeECID()
    }
    
    // Needs to be called out of init method to trigger willSet
    private func initializeECID() {
        var localVisitor = getECIDFromDisk()
        if let existingId = config.adobeVisitorExistingEcid, localVisitor?.experienceCloudID != existingId {
            localVisitor = AdobeVisitor(experienceCloudID: existingId)
        }
        if let localVisitor = localVisitor {
            self.visitor = localVisitor
            if let adobeCustomVisitorId = config.adobeVisitorCustomVisitorId,
                let dataProviderId = config.adobeVisitorDataProviderId {
                linkECIDToKnownIdentifier(adobeCustomVisitorId,
                                          dataProviderId: dataProviderId,
                                          authState: config.adobeVisitorAuthState,
                                          visitor: localVisitor)
            } else if localVisitor.shouldRefresh() {
                refreshECID(visitor: localVisitor)
            }
        } else {
            getAndLink(config.adobeVisitorCustomVisitorId,
                       adobeDataProviderId: config.adobeVisitorDataProviderId,
                       authState: config.adobeVisitorAuthState)
        }
    }

    /// - Returns: Optional `AdobeVisitor` instance
    func getECIDFromDisk() -> AdobeVisitor? {
        if let ecID = diskStorage?.retrieve(as: AdobeVisitor.self) {
            return ecID
        }
        return nil
    }

    /// Retrieves a new ECID from the Adobe Visitor API
    /// - Parameters:
    ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
    ///     - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
    func getECID(completion: AdobeVisitorCompletion? = nil) {
        visitorAPI?.getNewECID { result in
            self.completeCall(result: result)
            completion?(result)
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this user identifier
    ///     - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
    func getAndLink(_ knownId: String?,
                    adobeDataProviderId: String?,
                    authState: AdobeVisitorAuthState?) {
        getECID() { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let visitor):
                if let adobeCustomVisitorId = knownId,
                    let dataProviderId = adobeDataProviderId {
                    self.linkECIDToKnownIdentifier(adobeCustomVisitorId,
                                                   dataProviderId: dataProviderId,
                                                   authState: authState,
                                                   visitor: visitor)
                }
            case .failure:
                break
            }
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this user identifier
    ///     - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
    func linkECIDToKnownIdentifier(_ customVisitorId: String,
                                   dataProviderId: String,
                                   authState: AdobeVisitorAuthState? = nil,
                                   visitor: AdobeVisitor,
                                   completion: AdobeVisitorCompletion? = nil) {
        visitorAPI?.linkExistingECIDToKnownIdentifier(customVisitorId: customVisitorId,
                                                     dataProviderID: dataProviderId,
                                                     experienceCloudId: visitor.experienceCloudID,
                                                     authState: config.adobeVisitorAuthState) { result in
            self.completeCall(result: result)
            completion?(result)
        }
    }

    /// Sends a refresh request to the Adobe Visitor API. Used if the TTL has expired.
    /// - Parameters:
    ///     - visitor: `AdobeVisitor` containing the current ECID
    func refreshECID(visitor: AdobeVisitor) {
        visitorAPI?.refreshECID(existingECID: visitor.experienceCloudID, completion: self.completeCall)
    }
    
    /// Resets the Adobe Experience Cloud ID. A new ID will be requested immediately
    ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
    ///     - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
    func resetECID(completion: AdobeVisitorCompletion? = nil) {
        TealiumQueues.backgroundSerialQueue.async {
            self.visitor = nil
            self.onECIDUpdate.clear()
            self.visitorAPI?.resetNetworkSession()
            self.getECID(completion: completion)
        }
    }
    
    private func completeCall(result: AdobeResult) {
        switch result {
        case .success(let visitor):
            self.error = nil
            self.visitor = visitor
        case .failure(let error):
            self.error = error
            // An error doesn't delete the previous visitor present as it's always valid for us
        }
    }
}

extension TealiumAdobeVisitorModule: QueryParameterProvider {

    public func provideParameters(completion: @escaping ([URLQueryItem]) -> Void) {
        TealiumQueues.backgroundSerialQueue.async {
            self.onECIDUpdate.subscribeOnce { [weak self] ecid in
                guard let self = self else { return }
                completion(self.getQueryParams(ecid: ecid))
            }
        }
    }

    private func getQueryParams(ecid: String?) -> [URLQueryItem] {
        guard let ecid = ecid,
              let orgId = config.adobeVisitorOrgId else {
            return []
        }
        typealias Query = AdobeQueryParamConstants
        let timestamp = Date().unixTimeSeconds
        return [URLQueryItem(name: Query.adobeMc, value: "\(Query.MCID)=\(ecid)|\(Query.MCORGID)=\(orgId)|\(Query.TS)=\(timestamp)")]
    }

    public func decorateUrl(_ url: URL, completion: @escaping (URL) -> Void) {
        provideParameters { items in
            completion(url.appendingQueryItems(items))
        }
    }
}

extension TealiumAdobeVisitorModule: DispatchValidator {
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        guard let _ = config.adobeVisitorOrgId else {
            return (false, [AdobeVisitorModuleKeys.error: AdobeVisitorModuleConstants.missingOrgId])
        }
        guard let data = self.data else {
            if let error = error {
                return (false, [AdobeVisitorModuleKeys.error: "Unrecoverable error: \(error.localizedDescription)"])
            }
            return (true, [TealiumDataKey.queueReason: AdobeVisitorError.missingExperienceCloudID.localizedDescription])
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
