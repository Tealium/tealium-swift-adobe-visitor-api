//
//  AdobeECIDCodable.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public struct AdobeVisitor: Codable {
    public var experienceCloudID: String
    public var idSyncTTL: String?
    public var dcsRegion: String?
    public var blob: String?
    public var nextRefresh: Date?

    enum CodingKeys: String, CodingKey {
        case experienceCloudID = "d_mid"
        case idSyncTTL = "id_sync_ttl"
        case nextRefresh
        case dcsRegion = "dcs_region"
        case blob = "d_blob"
    }

    init?(experienceCloudID: String?, idSyncTTL: String? = nil, dcsRegion: String? = nil, blob: String? = nil, nextRefresh: Date? = nil) {
        guard let ecId = experienceCloudID else {
            return nil
        }
        self.init(experienceCloudID: ecId, idSyncTTL: idSyncTTL, dcsRegion: dcsRegion, blob: blob, nextRefresh: nextRefresh)
    }
    
    init(experienceCloudID: String, idSyncTTL: String? = nil, dcsRegion: String? = nil, blob: String? = nil, nextRefresh: Date? = nil) {
        self.experienceCloudID = experienceCloudID
        self.idSyncTTL = idSyncTTL
        self.dcsRegion = dcsRegion
        self.blob = blob
        self.nextRefresh = nextRefresh
    }

    static func initWithDictionary(_ dict: [String: Any]) -> AdobeVisitor? {
        guard let ecID = dict[AdobeVisitorKeys.experienceCloudId.rawValue] as? String, ecID != "<null>" else {
            return nil
        }
        return AdobeVisitor(experienceCloudID: ecID)
            .mergingDictionary(dict)
    }
    
    func mergingDictionary(_ dict: [String: Any]?) -> AdobeVisitor {
        guard let dict = dict else {
            return self
        }
        var adobeValues = [String: String]()
        for (key, value) in dict {
            adobeValues[key] = "\(value)"
        }
        let idSyncTTL = adobeValues[AdobeVisitorKeys.idSyncTTL.rawValue] ?? self.idSyncTTL
        
        let nextRefresh = Self.getFutureDate(adding: idSyncTTL)
        let dcsRegion = adobeValues[AdobeVisitorKeys.region.rawValue] ?? self.dcsRegion
        let blob = adobeValues[AdobeVisitorKeys.encryptedMetaData.rawValue] ?? self.blob
        return AdobeVisitor(experienceCloudID: self.experienceCloudID,
                            idSyncTTL: idSyncTTL,
                            dcsRegion: dcsRegion,
                            blob: blob,
                            nextRefresh: nextRefresh)
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
    
    func shouldRefresh() -> Bool {
        guard let nextRefresh = nextRefresh else {
            return true
        }
        return Date() >= nextRefresh
    }
}
