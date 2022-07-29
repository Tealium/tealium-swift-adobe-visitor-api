//
//  AdobeVisitorAPI.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//


import Foundation

public typealias AdobeResult = Result<AdobeVisitor, Error>

public typealias AdobeVisitorCompletion = ((AdobeResult) -> Void)

protocol AdobeExperienceCloudIDService: AnyObject {
    var visitor: AdobeVisitor? { get set }

    func getNewECID(completion: @escaping AdobeVisitorCompletion)

    func linkExistingECIDToKnownIdentifier(customVisitorId: String,
                                           dataProviderID: String,
                                           experienceCloudId: String,
                                           authState: AdobeVisitorAuthState?,
                                           completion: AdobeVisitorCompletion?)

    func refreshECID(existingECID: String,
                     completion: @escaping AdobeVisitorCompletion)

    func resetNetworkSession()

}


class AdobeVisitorAPI: AdobeExperienceCloudIDService {

    var visitor: AdobeVisitor?
    var networkSession: NetworkSession
    var adobeOrgId: String
    
    var retryManager: Retryable

    /// - Parameters:
    ///     - networkSession: `NetworkSession` to use for all network requests. Used for unit testing. Defaults to `URLSession.shared`
    ///     - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - existingVisitor: `AdobeVisitor` representing an existing visitor object with ECID to use
    init(networkSession: NetworkSession = URLSession.shared,
         retryManager: Retryable,
         adobeOrgId: String,
         existingVisitor: AdobeVisitor? = nil) {
        if let urlSession = networkSession as? URLSession {
            urlSession.configuration.httpCookieStorage = nil
        }
        self.visitor = existingVisitor
        self.adobeOrgId = adobeOrgId
        self.networkSession = networkSession
        self.retryManager = retryManager
    }

    /// Allows the API user to determine whether cookies will be maintained on future requests to the Visitor API
    /// If disabled, cookies may be sent on subsequent requests in the same session, but will not be stored for future sessions (ephemeral URLSession)
    /// - Parameters:
    ///     - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - enableCookies: `Bool` to determine if cookies should be persisted for future sessions. Recommended: `true`.
    convenience init(retryManager: Retryable,
                     adobeOrgId: String,
                     enableCookies: Bool) {
        var urlSessionConfig: URLSessionConfiguration

        if !enableCookies {
            urlSessionConfig = URLSessionConfiguration.ephemeral
        } else {
            urlSessionConfig = URLSessionConfiguration.default
        }

        let urlSession = URLSession(configuration: urlSessionConfig)

        self.init(networkSession: urlSession, retryManager: retryManager, adobeOrgId: adobeOrgId)
    }

    /// Sends a request to the Adobe Visitor API, and calls completion with `Result`
    /// - Parameters:
    ///     - url: `URL` for the request to be sent to
    ///     - completion: Optional `AdobeVisitorCompletion` block to be called when the response is returned
    func sendRequest(url: URL,
                     retries: Int = 0,
                     completion: AdobeVisitorCompletion?) {
        let urlRequest = URLRequest(url: url)
        networkSession.loadData(from: urlRequest) { result in
            switch result {
            case .success((_, let data)):
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let json = json,
                   let adobeValues = AdobeVisitor.initWithDictionary(json) {
                    completion?(.success(adobeValues))
                } else if let ecID = self.visitor {
                    completion?(.success(ecID.mergingDictionary(json)))
                } else {
                    completion?(.failure(AdobeVisitorError.invalidJSON))
                }
            case .failure(let error):
                if retries < self.retryManager.maxRetries {
                    self.retryManager.submit {
                        self.sendRequest(url: url, retries: retries + 1, completion: completion)
                    }
                } else {
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Generates the Adobe CID URL parameter
    /// - Parameters:
    ///     - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - Returns: `String containing the encoded d_cid parameter`
    func generateCID(dataProviderId: String,
                     customVisitorId: String,
                     authState: AdobeVisitorAuthState?) -> String {
        return [dataProviderId, customVisitorId, authState?.rawValue.description]
            .compactMap() { $0 }
            .joined(separator: AdobeStringConstants.dataProviderIdSeparator.rawValue)
    }


    /// Generates a Demdex URL for a new visitor with no prior ECID
    /// - Parameters:
    ///     - withAdobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - existingECID: `String` containing an existing ECID to use
    ///     - version: `Int` representing the API version. Can be omitted.
    /// - Returns: `URL` for a request to the Adobe Visitor API to retrieve a new ECID for the current user
    func getNewUserAdobeIdURL(existingECID: String? = nil,
                              version: Int = AdobeIntConstants.apiVersion.rawValue) -> URL? {
        generateURL(params: [
            (.orgId, self.adobeOrgId),
            (.experienceCloudId, existingECID),
            (.version, version.description)
        ])
    }

    /// Generates a Demdex URL to link a known visitor ID to an ECID
    /// - Parameters:
    ///     - version: `Int` representing the API version. Can be omitted.
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    ///     - experienceCloudID: `String` containing the current ECID for this visitor
    ///     - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - Returns: `URL` for a request to the Adobe Visitor API to link a known visitor ID to an ECID
    func getLinkKnownIdURL(customVisitorId: String,
                           dataProviderId: String,
                           experienceCloudId: String,
                           authState: AdobeVisitorAuthState?,
                           version: Int = AdobeIntConstants.apiVersion.rawValue) -> URL? {
        let dataProviderString = generateCID(dataProviderId: dataProviderId, customVisitorId: customVisitorId, authState: authState)
        return generateURL(params: [
            (.orgId, self.adobeOrgId),
            (.experienceCloudId, experienceCloudId),
            (.dataProviderId, dataProviderString),
            (.version, version.description)
        ])
    }
    
    func generateURL(params: [(AdobeVisitorKeys, String?)]) -> URL? {
        return URL(string: AdobeStringConstants.defaultAdobeURL.rawValue)?
            .appendingQueryItems(params.compactMap { key, value in
                guard let value = value else { return nil }
                return URLQueryItem(name: key.rawValue, value: value)
            })
    }
    
    /// Requests a new Adobe ECID from the Adobe Visitor API
    /// - Parameter completion: `AdobeVisitorCompletion` to be called when the new ID is returned from the Adobe Visitor API
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
        guard let url = getNewUserAdobeIdURL() else { return }
        sendRequest(url: url) { result in
            // attempt to store current state in memory
            self.visitor = try? result.get()
            completion(result)
        }
    }

    /// Resets the URLSession to delete cookies
    func resetNetworkSession() {
        networkSession.reset()
    }

    /// Requests a new Adobe ECID from the Adobe Visitor API
    /// - Parameters:
    ///     - existingECID: `String` containing the last known ECID to refresh
    ///     - completion: `AdobeVisitorCompletion` to be called when the new ID is returned from the Adobe Visitor API
    func refreshECID(existingECID: String,
                     completion: @escaping AdobeVisitorCompletion) {
        guard let url = getNewUserAdobeIdURL(existingECID: existingECID) else { return }
        sendRequest(url: url) { result in
            // attempt to store current state in memory
            self.visitor = try? result.get()
            completion(result)
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    ///     - experienceCloudID: `String` containing the current ECID for this visitor
    ///     - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    ///     - completion: Optional `AdobeVisitorCompletion` block to be called when the response is returned
    func linkExistingECIDToKnownIdentifier(customVisitorId: String,
                                           dataProviderID: String,
                                           experienceCloudId: String,
                                           authState: AdobeVisitorAuthState?,
                                           completion: AdobeVisitorCompletion?) {
        guard let url = getLinkKnownIdURL(customVisitorId: customVisitorId,
                                       dataProviderId: dataProviderID,
                                       experienceCloudId: experienceCloudId,
                                       authState: authState) else {
            return
        }
        sendRequest(url: url) { result in
            switch result {
            case .success(let visitor):
                completion?(.success(visitor))
            case .failure:
                // although the call failed, this is ok, as we already have a known ECID, but no new ECID was returned
                guard let visitor = self.visitor else {
                    completion?(.failure(AdobeVisitorError.missingExperienceCloudID))
                    return
                }
                completion?(.success(visitor))
            }
        }
    }

    deinit {
        networkSession.invalidateAndClose()
    }
}
