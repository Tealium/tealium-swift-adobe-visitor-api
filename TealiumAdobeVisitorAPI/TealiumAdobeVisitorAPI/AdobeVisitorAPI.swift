//
//  AdobeVisitorAPI.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//


import Foundation

public typealias AdobeResult = Result<AdobeVisitor, Error>

public typealias AdobeVisitorCompletion = ((AdobeResult) -> Void)


protocol AdobeExperienceCloudIDService {
    var visitor: AdobeVisitor? { get set }

    func getNewECID(completion: @escaping AdobeVisitorCompletion)

    func getNewECIDAndLink(customVisitorId: String,
                           dataProviderId: String,
                           authState: AdobeVisitorAuthState?,
                           completion: AdobeVisitorCompletion?)

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

    /// - Parameters:
    ///     - networkSession: `NetworkSession` to use for all network requests. Used for unit testing. Defaults to `URLSession.shared`
    ///     - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - existingVisitor: `AdobeVisitor` representing an existing visitor object with ECID to use
    init(networkSession: NetworkSession = URLSession.shared,
         adobeOrgId: String,
         existingVisitor: AdobeVisitor? = nil) {
        if let urlSession = networkSession as? URLSession {
            urlSession.configuration.httpCookieStorage = nil
        }
        self.visitor = existingVisitor
        self.adobeOrgId = adobeOrgId
        self.networkSession = networkSession
    }

    /// Allows the API user to determine whether cookies will be maintained on future requests to the Visitor API
    /// If disabled, cookies may be sent on subsequent requests in the same session, but will not be stored for future sessions (ephemeral URLSession)
    /// - Parameters:
    ///     - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - enableCookies: `Bool` to determine if cookies should be persisted for future sessions. Recommended: `true`.
    convenience init(adobeOrgId: String,
                     enableCookies: Bool) {
        var urlSessionConfig: URLSessionConfiguration

        if !enableCookies {
            urlSessionConfig = URLSessionConfiguration.ephemeral
        } else {
            urlSessionConfig = URLSessionConfiguration.default
        }

        let urlSession = URLSession(configuration: urlSessionConfig)

        self.init(networkSession: urlSession, adobeOrgId: adobeOrgId)
    }

    /// Removes unneeded keys from the Adobe Visitor API response
    func removeExtraKeys(_ adobeVistorResponse: [String: Any]) -> [String: Any] {
        return adobeVistorResponse.filter { (key, value) in
            return AdobeVisitorKeys.isValidKey(key)
        }
    }

    /// Sends a request to the Adobe Visitor API, and calls completion with `Result`
    /// - Parameters:
    ///     - url: `URL` for the request to be sent to
    ///     - completion: Optional `AdobeVisitorCompletion` block to be called when the response is returned
    func sendRequest(url: URL,
                     completion: AdobeVisitorCompletion?) {
        let urlRequest = URLRequest(url: url)
        networkSession.loadData(from: urlRequest) { result in
            switch result {
            case .success((_, let data)):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let adobeValues = AdobeVisitor.initWithDictionary(self.removeExtraKeys(json)) {
                    completion?(.success(adobeValues))
                } else if let ecID = self.visitor {
                    completion?(.success(ecID))
                } else {
                    completion?(.failure(AdobeVisitorError.invalidJSON))
                }
            case .failure(let error):
                completion?(.failure(error))
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
        return [dataProviderId, customVisitorId, authState?.rawValue.description].compactMap {
                    $0
                }
                .joined(separator: AdobeStringConstants.dataProviderIdSeparator.rawValue)
    }


    /// Generates a Demdex URL for a new visitor with no prior ECID
    /// - Parameters:
    ///     - withAdobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    ///     - existingECID: `String` containing an existing ECID to use
    ///     - version: `Int` representing the API version. Can be omitted.
    /// - Returns: `URL` for a request to the Adobe Visitor API to retrieve a new ECID for the current user
    func getNewUserAdobeIdURL(withAdobeOrgId orgId: String,
                              existingECID: String? = nil,
                              version: Int = AdobeIntConstants.apiVersion.rawValue) -> URL? {
        if let existingECID = existingECID {
            return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.orgId.rawValue)=\(orgId)&\(AdobeVisitorKeys.experienceCloudId.rawValue)=\(existingECID)&\(AdobeVisitorKeys.version.rawValue)=\(version)")
        } else {
            return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.orgId.rawValue)=\(orgId)&\(AdobeVisitorKeys.version.rawValue)=\(version)")
        }
    }

    /// Generates a Demdex URL to link a known visitor ID to an ECID
    /// - Parameters:
    ///     - version: `Int` representing the API version. Can be omitted.
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    ///     - experienceCloudID: `String` containing the current ECID for this visitor
    ///     - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - Returns: `URL` for a request to the Adobe Visitor API to link a known visitor ID to an ECID
    func getExistingUserIdURL(version: Int = AdobeIntConstants.apiVersion.rawValue,
                              customVisitorId: String,
                              dataProviderId: String,
                              experienceCloudId: String,
                              authState: AdobeVisitorAuthState?
    ) -> URL? {
        let dataProviderString = generateCID(dataProviderId: dataProviderId, customVisitorId: customVisitorId, authState: authState)

        return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.experienceCloudId.rawValue)=\(experienceCloudId)&\(AdobeVisitorKeys.dataProviderId.rawValue)=\(dataProviderString)&\(AdobeVisitorKeys.version)=\(version.description)")
    }

    /// Requests a new Adobe ECID from the Adobe Visitor API
    /// - Parameter completion: `AdobeVisitorCompletion` to be called when the new ID is returned from the Adobe Visitor API
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
        if let url = getNewUserAdobeIdURL(withAdobeOrgId: adobeOrgId) {
            sendRequest(url: url) { result in
                // attempt to store current state in memory
                self.visitor = try? result.get()
                completion(result)
            }
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
        if let url = getNewUserAdobeIdURL(withAdobeOrgId: adobeOrgId, existingECID: existingECID) {
            sendRequest(url: url) { result in
                // attempt to store current state in memory
                self.visitor = try? result.get()
                completion(result)
            }
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
        if let url = getExistingUserIdURL(customVisitorId: customVisitorId,
                                          dataProviderId: dataProviderID,
                                          experienceCloudId: experienceCloudId,
                                          authState: authState) {
            sendRequest(url: url) { result in
                switch result {
                case .success(var visitor):
                    // ensure ECID is always present in response
                    if visitor.experienceCloudID == nil {
                        visitor.experienceCloudID = experienceCloudId
                    }
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

    }

    /// Gets a new Adobe Experience Cloud ID, then links it to a known ID with a 2nd HTTP request
    /// - Parameters:
    ///     - customVisitorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    ///     - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    ///     - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    ///     - completion: Optional `AdobeVisitorCompletion` block to be called when the response is returned
    func getNewECIDAndLink(customVisitorId: String,
                           dataProviderId: String,
                           authState: AdobeVisitorAuthState?,
                           completion: AdobeVisitorCompletion?) {
        getNewECID { result in
            switch result {
            case .success(let visitor):
                guard let experienceCloudID = visitor.experienceCloudID else {
                    completion?(.failure(AdobeVisitorError.missingExperienceCloudID))
                    return
                }
                self.linkExistingECIDToKnownIdentifier(customVisitorId: customVisitorId,
                                                       dataProviderID: dataProviderId,
                                                       experienceCloudId: experienceCloudID,
                                                       authState: authState) { result in
                    switch result {
                    case .success(let ECID):
                        completion?(.success(ECID))
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    deinit {
        networkSession.invalidateAndClose()
    }
}
