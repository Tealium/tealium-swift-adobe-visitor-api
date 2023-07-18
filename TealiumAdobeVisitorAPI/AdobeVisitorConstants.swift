//
//  AdobeVisitorConstants.swift
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

enum AdobeQueryParamConstants {
    static let adobeMc = "adobe_mc"
    static let MCID = "MCMID"
    static let MCORGID = "MCORGID"
    static let TS = "TS"
}

enum AdobeVisitorKeys: String, CaseIterable {
    case experienceCloudId = "d_mid"
    case orgId = "d_orgid"
    case dataProviderId = "d_cid"
    case region = "dcs_region"
    case encryptedMetaData = "d_blob"
    case version = "d_ver"
    case idSyncTTL = "id_sync_ttl"

    static func isValidKey(_ key: String) -> Bool {
        return AdobeVisitorKeys.allCases.map { caseItem in
            return caseItem.rawValue
        }.contains(key)
    }
}


struct TealiumAdobeVisitorConstants {
    public static let orgId = "adobe_org_id"
    public static let customVisitorId = "adobe_custom_visitor_id"
    public static let existingEcid = "adobe_existing_ecid"
    public static let dataProviderId = "adobe_data_provider_id"
    public static let authState = "adobe_auth_state"
    public static let orgIdSuffix = "@AdobeOrg"
    public static let moduleName = "adobevisitor"
    public static let retries = "retries"
}

public enum AdobeVisitorAuthState: Int, CustomStringConvertible {
    public var description: String {
        return "\(self.rawValue)"
    }

    case unknown = 0
    case authenticated = 1
    case loggedOut = 2

}

enum AdobeIntConstants: Int {
    case apiVersion = 2
}

enum AdobeStringConstants: String {
    // %01 is a non-printing control character
    case dataProviderIdSeparator = "%01"
    case defaultAdobeURL = "https://dpm.demdex.net/id"
}

public enum AdobeVisitorError: Error, LocalizedError {
    case missingExperienceCloudID
    case missingOrgID
    case invalidJSON

    public var localizedDescription: String {
        switch self {
        case .missingExperienceCloudID:
            return NSLocalizedString("Adobe Experience Cloud ID not available", comment: "missingExperienceCloudID")
        case .invalidJSON:
            return NSLocalizedString("Adobe Experience Cloud ID service returned invalid JSON", comment: "invalidJSON")
        case .missingOrgID:
            return NSLocalizedString("Adobe Org ID missing", comment: "missingOrgID")
        }
    }
}

enum AdobeVisitorModuleKeys {
    static let error = "adobe_error"
}

enum AdobeVisitorModuleConstants {
    static let successMessage = "Adobe Visitor ID Retrieved Successfully"
    static let missingOrgId = "Org ID Not Set. ECID will be missing from track requests"
    static let failureMessage = "Adobe Visitor ID suffered unrecoverable error"
}
