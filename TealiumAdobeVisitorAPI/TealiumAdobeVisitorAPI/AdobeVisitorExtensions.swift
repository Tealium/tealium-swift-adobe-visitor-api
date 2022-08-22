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


extension TealiumDataKey {
    public static let adobeEcid = "adobe_ecid"
}

public extension Collectors {
    static let AdobeVisitor = TealiumAdobeVisitorModule.self
}

public extension Tealium {

    class AdobeVisitorWrapper {
        private unowned var tealium: Tealium
        
        private var module: TealiumAdobeVisitorModule? {
            (tealium.zz_internal_modulesManager?.modules.first {
                $0 is TealiumAdobeVisitorModule
            }) as? TealiumAdobeVisitorModule
        }
        
        /// Returns the full Adobe Visitor object
        public var visitor: AdobeVisitor? {
            return module?.visitor
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
            guard let module = module else {
                return
            }
            if let visitor = module.visitor {
                module.linkECIDToKnownIdentifier(knownId,
                                                 dataProviderId: adobeDataProviderId,
                                                 authState: authState,
                                                 visitor: visitor,
                                                 completion: completion)
            } else {
                module.getAndLink(knownId,
                                  adobeDataProviderId: adobeDataProviderId,
                                  authState: authState)
            }
        }
        
        /// Resets the Adobe Experience Cloud ID. A new ID will be requested immediately
        /// - Parameters:
        ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
        ///         - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
        public func resetVisitor(completion: AdobeVisitorCompletion? = nil) {
            module?.resetECID(completion: completion)
        }
        
        /// Decorates the provided URL with the query params for the Adobe ECID
        ///
        /// This method waits for ongoing ECID fetches before decorating the url with the latests value.
        ///
        /// - Parameters:
        ///     - url: The url to decorat
        ///     - completion: The block that will be called at end of the decoration process
        ///         - result: The URL after the decoration process, or the input URL if no parameter has been added
        public func decorateUrl(_ url: URL, completion: @escaping (URL) -> Void) {
            module?.provideParameters { items in
                completion(url.appendingQueryItems(items))
            }
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
