//
// TealiumHelper.swift
// TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//


import Foundation
import TealiumSwift
import TealiumAdobeVisitorAPI

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
}

class TealiumHelper: ObservableObject {

    static let shared = TealiumHelper()
    
    let config = TealiumConfig(account: TealiumConfiguration.account,
        profile: TealiumConfiguration.profile,
        environment: TealiumConfiguration.environment)

    @Published var tealium: Tealium?
    @Published var currentECID: String?
    
    public func start(orgId: String?, knownId: String?, existingECID: String?) {
        self.tealium = nil
        self.currentECID = nil
        config.shouldUseRemotePublishSettings = false
        config.batchingEnabled = false
        config.remoteAPIEnabled = true
        if let orgId = orgId {
            config.adobeVisitorOrgId = orgId
        }
        if let knownId = knownId {
            config.adobeVisitorCustomVisitorId = knownId
            config.adobeVisitorDataProviderId = "email"
        }
        config.adobeVisitorExistingEcid = existingECID

        config.adobeVisitorOrgId = orgId
        config.logLevel = .info
        config.collectors = [Collectors.AdobeVisitor, Collectors.Lifecycle]
        config.dispatchers = [Dispatchers.TagManagement]
        config.dispatchListeners = [TealiumHelper.shared]
        tealium = Tealium(config: config)
    }
    
    private init() {}

    func trackView(title: String, data: [String: Any]?) {
        let tealiumView = TealiumView(title, dataLayer: data)
        tealium?.track(tealiumView)
    }

    func trackEvent(title: String, data: [String: Any]?) {
        let tealiumEvent = TealiumEvent(title, dataLayer: data)
        tealium?.track(tealiumEvent)
    }
    
    func getECID() -> String? {
        return tealium?.adobeVisitorApi?.visitor?.experienceCloudID
    }
    
    func resetECID() {
        tealium?.adobeVisitorApi?.resetVisitor()
    }
    
    func linkToKnownId(id: String) {
        tealium?.adobeVisitorApi?.linkECIDToKnownIdentifier(id, adobeDataProviderId: "email", authState: .unknown)
    }

}

extension TealiumHelper: DispatchListener {
    func willTrack(request: TealiumRequest) {
        guard let ecid = (request as? TealiumTrackRequest)?.trackDictionary["adobe_ecid"] as? String
              else {
            return
        }
        DispatchQueue.main.async {
            self.currentECID = ecid
        }
    }
    
    
}
