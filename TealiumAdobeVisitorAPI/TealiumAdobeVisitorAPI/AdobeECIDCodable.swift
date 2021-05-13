//
//  AdobeECIDCodable.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public struct AdobeVisitor: Codable {
    public var experienceCloudID: String?
    public var idSyncTTL: String?
    public var dcsRegion: String?
    public var blob: String?
    public var nextRefresh: Date?
    public var isEmpty: Bool {
        experienceCloudID == nil &&
            idSyncTTL == nil &&
            dcsRegion == nil &&
            blob == nil &&
            nextRefresh == nil
    }

    enum CodingKeys: String, CodingKey {
        case experienceCloudID = "d_mid"
        case idSyncTTL = "id_sync_ttl"
        case nextRefresh
        case dcsRegion = "dcs_region"
        case blob = "d_blob"
    }

    init?(experienceCloudID: String?, idSyncTTL: String?, dcsRegion: String?, blob: String?, nextRefresh: Date?) {
        guard let ecId = experienceCloudID else {
            return nil
        }
        self.experienceCloudID = ecId
        self.idSyncTTL = idSyncTTL
        self.dcsRegion = dcsRegion
        self.blob = blob
        self.nextRefresh = nextRefresh
    }

    static func initWithDictionary(_ dict: [String: Any]) -> AdobeVisitor? {
        var adobeValues = [String: String]()
        for (key, value) in dict {
            adobeValues[key] = "\(value)"
        }
        let ecID = adobeValues[AdobeVisitorKeys.experienceCloudId.rawValue]
        if ecID == "<null>" || ecID == nil {
            return nil
        }
        let idSyncTTL = adobeValues[AdobeVisitorKeys.idSyncTTL.rawValue]

        let nextRefresh = getFutureDate(adding: idSyncTTL)
        let dcsRegion = adobeValues[AdobeVisitorKeys.region.rawValue]
        let blob = adobeValues[AdobeVisitorKeys.encryptedMetaData.rawValue]
        return AdobeVisitor(experienceCloudID: ecID, idSyncTTL: idSyncTTL, dcsRegion: dcsRegion, blob: blob, nextRefresh: nextRefresh)
    }

    static func getFutureDate(adding ttlSeconds: String?) -> Date? {
        guard let ttlSeconds = ttlSeconds,
              let seconds = Int(ttlSeconds) else {
            return nil
        }
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(seconds, for: .second)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
    }

}
