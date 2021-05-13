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

class TealiumHelper {

    static let shared = TealiumHelper()
    
    static let config = TealiumConfig(account: TealiumConfiguration.account,
        profile: TealiumConfiguration.profile,
        environment: TealiumConfiguration.environment)

    static var tealium: Tealium?
    
    public static func start(orgId: String?) {
        config.shouldUseRemotePublishSettings = false
        config.batchingEnabled = false
        config.remoteAPIEnabled = true
        if let orgId = orgId {
            config.adobeVisitorOrgId = orgId
        }

        config.adobeVisitorOrgId = orgId
        config.logLevel = .info
        config.collectors = [Collectors.AdobeVisitor, Collectors.Lifecycle]
        config.dispatchers = [Dispatchers.Collect]
        config.dispatchListeners = [TealiumHelper.shared]
        TealiumHelper.tealium = Tealium(config: config)
    }
    
    private init() {}

    class func trackView(title: String, data: [String: Any]?) {
        let tealiumView = TealiumView(title, dataLayer: data)
        TealiumHelper.tealium?.track(tealiumView)
    }

    class func trackEvent(title: String, data: [String: Any]?) {
        let tealiumEvent = TealiumEvent(title, dataLayer: data)
        TealiumHelper.tealium?.track(tealiumEvent)
    }
    
    class func getECID() -> String? {
        return TealiumHelper.tealium?.adobeVisitorApi?.visitor?.experienceCloudID
    }
    
    class func resetECID() {
        TealiumHelper.tealium?.adobeVisitorApi?.resetVisitor()
    }
    
    class func linkToKnownId(id: String) {
        TealiumHelper.tealium?.adobeVisitorApi?.linkECIDToKnownIdentifier(id, adobeDataProviderId: "email", authState: .unknown)
    }

}

extension TealiumHelper: DispatchListener {
    func willTrack(request: TealiumRequest) {
        guard let ecid = (request as? TealiumTrackRequest)?.trackDictionary["adobe_ecid"] as? String
              else {
            return
        }
        let notification = Notification(name: Notification.Name("ecid"), object: nil, userInfo: ["ecid":ecid])
        NotificationCenter.default.post(notification)
    }
    
    
}
