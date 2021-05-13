//
//  AdobeVisitorExtensions.swift
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

public extension Collectors {
    static let AdobeVisitor = TealiumAdobeVisitorModule.self
}

public extension Tealium {

    class AdobeVisitorWrapper {
        private unowned var tealium: Tealium
        
        /// Returns the full Adobe Visitor object
        public var visitor: AdobeVisitor? {
            guard let module = (tealium.zz_internal_modulesManager?.modules.first {
                $0 is TealiumAdobeVisitorModule
            }) as? TealiumAdobeVisitorModule else {
                return nil
            }
            return module.visitor
        }
        
        /// Links a known visitor ID to an ECID
        /// - Parameters:
        ///    - knownId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
        ///    - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
        ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
        ///         - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
        public func linkECIDToKnownIdentifier(_ knownId: String,
                                              adobeDataProviderId: String,
                                              authState: AdobeVisitorAuthState? = nil,
                                              completion: AdobeVisitorCompletion? = nil) {
            guard let module = (tealium.zz_internal_modulesManager?.modules.first {
                $0 is TealiumAdobeVisitorModule
            }) as? TealiumAdobeVisitorModule else {
                return
            }
            module.linkECIDToKnownIdentifier(knownId, dataProviderId: adobeDataProviderId, authState: authState, completion: completion)
        }
        
        /// Resets the Adobe Experience Cloud ID. A new ID will be requested immediately
        /// - Parameters:
        ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
        ///         - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
        public func resetVisitor(completion: AdobeVisitorCompletion? = nil) {
            guard let module = (tealium.zz_internal_modulesManager?.modules.first {
                $0 is TealiumAdobeVisitorModule
            }) as? TealiumAdobeVisitorModule else {
                return
            }
            module.resetECID()
        }

        
        init(tealium: Tealium) {
            self.tealium = tealium
        }
    }
    
    /// Provides API methods to interact with the Adobe Visitor API module
    var adobeVisitorApi: AdobeVisitorWrapper? {
        return AdobeVisitorWrapper(tealium: self)
    }

}

public extension TealiumConfig {

    var adobeVisitorOrgId: String? {
        get {
            options[TealiumAdobeVisitorConstants.orgId] as? String
        }

        set {
            if var orgId = newValue {
                if !orgId.hasSuffix(TealiumAdobeVisitorConstants.orgIdSuffix) {
                    orgId = "\(orgId)\(TealiumAdobeVisitorConstants.orgIdSuffix)"
                }
                options[TealiumAdobeVisitorConstants.orgId] = orgId
            } else {
                options[TealiumAdobeVisitorConstants.orgId] = nil
            }
        }
    }

    var adobeVisitorCustomVisitorId: String? {
        get {
            options[TealiumAdobeVisitorConstants.customVisitorId] as? String
        }

        set {
            options[TealiumAdobeVisitorConstants.customVisitorId] = newValue
        }
    }

    var adobeVisitorExistingEcid: String? {
        get {
            options[TealiumAdobeVisitorConstants.existingEcid] as? String
        }

        set {
            options[TealiumAdobeVisitorConstants.existingEcid] = newValue
        }
    }

    var adobeVisitorRetries: Int {
        get {
            options[TealiumAdobeVisitorConstants.retries] as? Int ?? 5
        }

        set {
            options[TealiumAdobeVisitorConstants.retries] = newValue
        }
    }

    var adobeVisitorDataProviderId: String? {
        get {
            options[TealiumAdobeVisitorConstants.dataProviderId] as? String
        }

        set {
            options[TealiumAdobeVisitorConstants.dataProviderId] = newValue
        }
    }

    var adobeVisitorAuthState: AdobeVisitorAuthState? {
        get {
            options[TealiumAdobeVisitorConstants.authState] as? AdobeVisitorAuthState
        }

        set {
            options[TealiumAdobeVisitorConstants.authState] = newValue
        }
    }

}
