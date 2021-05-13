//
//  AdobeVisitorModuleTests.swift
//  TealiumAdobeVisitorAPITests
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumAdobeVisitorAPI
import TealiumCore

class AdobeVisitorModuleTests: XCTestCase {
    
    var mockVisitorAPISuccess = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorSuccess(), adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    var mockVisitorAPISuccessEmptyECID = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorSuccessEmptyECID(), adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    var mockVisitorAPIFailure = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorFailure(), adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    static var testConfig: TealiumConfig {
        get {
            let config = TealiumConfig(account: "tealiummobile", profile: "demo", environment: "dev")
            config.collectors = []
            config.appDelegateProxyEnabled = false
            config.adobeVisitorOrgId = AdobeVisitorAPITestHelpers.adobeOrgId
            config.dispatchers = []
            return config
        }
    }
    
    static var testConfigNoOrgId: TealiumConfig {
        get {
            let config = TealiumConfig(account: "tealiummobile", profile: "demo", environment: "dev")
            config.collectors = []
            config.appDelegateProxyEnabled = false
            config.dispatchers = []
            return config
        }
    }
    static let dataLayer = DataLayer(config: testConfig)
    static var tealium: Tealium {
        get {
       let teal = Tealium(config: testConfig)
        return teal
    }}
    static var testContext = TealiumContext(config: testConfig, dataLayer: dataLayer, tealium: tealium)
    
    class TestRetryManager: Retryable {
        var queue: DispatchQueue
        var delay: TimeInterval?
        required init(queue: DispatchQueue, delay: TimeInterval?) {
            self.queue = queue
            self.delay = delay
        }
        
        func submit(completion: @escaping () -> Void) {
            queue.async {
                completion()
            }
        }
    }

    func testShouldQueueReturnsTrueWhenECIDIsMissing() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        let request = TealiumTrackRequest(data: [:])
        XCTAssertNil(module.visitor)
        XCTAssertTrue(module.shouldQueue(request: request).0)
    }
    
    func testShouldQueueReturnsFalseWhenECIDIsAvailable() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.visitor = AdobeVisitor(experienceCloudID: AdobeVisitorAPITestHelpers.ecID, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        let request = TealiumTrackRequest(data: [:])
        XCTAssertFalse(module.shouldQueue(request: request).0)
        XCTAssertEqual(module.shouldQueue(request: request).1!["adobe_ecid"] as! String, AdobeVisitorAPITestHelpers.ecID)
    }
    
    func testShouldQueueReturnsTrueWhenECIDIsNotAvailable() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.visitor = AdobeVisitor(experienceCloudID: nil, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        let request = TealiumTrackRequest(data: [:])
        XCTAssertTrue(module.shouldQueue(request: request).0)
    }
    
    func testShouldPurgeAlwaysReturnsFalse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        let request = TealiumTrackRequest(data: [:])
        XCTAssertNil(module.visitor)
        XCTAssertFalse(module.shouldPurge(request: request))
    }
    
    func testShouldQueueReturnsFalseIfOrgIdNotSet() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)

        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        module.config.adobeVisitorOrgId = nil
        
        let request = TealiumTrackRequest(data: [:])
        XCTAssertNil(module.visitor)
        XCTAssertNil(module.config.adobeVisitorOrgId)
        XCTAssertFalse(module.shouldQueue(request: request).0)
    }
    
    func testShouldDropAlwaysReturnsFalse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        let request = TealiumTrackRequest(data: [:])
        XCTAssertNil(module.visitor)
        XCTAssertFalse(module.shouldDrop(request: request))
    }
    
    func testLinkToKnownIdentifierRetriesOnFailureIfECIDAvailable() {
        let expectation = self.expectation(description: "linkToKnownIdentifier")
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
    
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStoragePopulated(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: MockVisitorAPILinkFailure(expectation: expectation, count: 5)) { _, _ in
            
        }
        
        module.linkECIDToKnownIdentifier("test@test.com", dataProviderId: "123456")
        

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertEqual(module.visitor!.experienceCloudID, AdobeVisitorAPITestHelpers.ecID)
            let shouldQueue = module.shouldQueue(request: TealiumTrackRequest(data: [:]))
            XCTAssertFalse(shouldQueue.0)
            XCTAssertNotNil(module.error)
            XCTAssertTrue(module.error! as! AdobeVisitorError == AdobeVisitorError.invalidJSON)
        }
    }
    
    func testExistingECIDUsedOnFailure() {
        let expectation = self.expectation(description: "failure")
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStoragePopulated(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: MockVisitorAPIRefreshFailure(expectation: expectation, count: 5)) { _, _ in
            
        }

        waitForExpectations(timeout: 10.0) { error in
            XCTAssertEqual(module.visitor!.experienceCloudID, AdobeVisitorAPITestHelpers.ecID)
            let shouldQueue = module.shouldQueue(request: TealiumTrackRequest(data: [:]))
            XCTAssertFalse(shouldQueue.0)
        }
    }
    
    func testECIDNotNullOnInvalidResponse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.getECID()
        XCTAssertNil(module.visitor)
    
    }
    
    func testECIDAvailableOnSuccessfulResponse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: nil, retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccess) { _, _ in
            
        }
        
        module.getECID()
        XCTAssertEqual(module.visitor!.experienceCloudID!, AdobeVisitorAPITestHelpers.ecID)
    }
    
    func testGetAndLinkRetriesOnFailure() {
        let expectation = self.expectation(description: "testGetAndLinkRetriesOnFailure")
        let config = AdobeVisitorModuleTests.testConfig.copy
        config.adobeVisitorCustomVisitorId = "abc123@123.com"
        config.adobeVisitorDataProviderId = "email"
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)

        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: MockVisitorAPIGetAndLinkFailure(expectation: expectation, count: 5)) { _, _ in

        }
        
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertEqual(module.error as? AdobeVisitorError, AdobeVisitorError.invalidJSON)
        
        }
    }
    
    func testDataNotReturnedIfECIDMissing() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.visitor = AdobeVisitor(experienceCloudID: nil, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        XCTAssertNil(module.data)
    }
    
    func testDataReturnedIfECIDIsSet() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.visitor = AdobeVisitor(experienceCloudID: AdobeVisitorAPITestHelpers.ecID, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        XCTAssertNotNil(module.data)
        XCTAssertEqual(module.data!["adobe_ecid"] as! String, AdobeVisitorAPITestHelpers.ecID)
    }
    
    func testInitWithoutOrgID() {
        let config = AdobeVisitorModuleTests.testConfigNoOrgId.copy
        XCTAssertNil(config.adobeVisitorOrgId)
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { result, _ in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as! AdobeVisitorError, AdobeVisitorError.missingOrgID)
            case .success:
                XCTFail("Should not pass due to missing org ID")
            }
        }
        let request = TealiumTrackRequest(data: [:])
        XCTAssertNil(module.visitor)
        XCTAssertFalse(module.shouldQueue(request: request).0)
    }
    
    func testGetECIDFromDiskRefreshesIfExpired() {
        let expectation = self.expectation(description: "testRefresh")
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
    
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: MockVisitorAPIRefreshSuccess(expectation: expectation, count: 5)) { _, _ in
            
        }
        
        XCTAssertNil(module.visitor)
        
        module.diskStorage = MockAdobeVisitorDiskStoragePopulated()
        let ecid = module.getECIDFromDisk()
        XCTAssertEqual(AdobeVisitorAPITestHelpers.ecID, ecid?.experienceCloudID)
        wait(for: [expectation], timeout: 1)
    }
    
    func testExistingDataUsedIfNoResponse() {
        
    }
    
    func testShouldQueueReturnsFalseIfNoDataAndRetriesExceeded() {
        
    }
    
    func testResetECID() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
    
        let module = TealiumAdobeVisitorModule(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStoragePopulated(), retryManager: TestRetryManager(queue: DispatchQueue(label: "test"), delay: nil), adobeVisitorAPI: MockVisitorAPILinkFailure(expectation: nil, count: 5)) { _, _ in
            
        }
        
        XCTAssertEqual(module.visitor!.experienceCloudID, AdobeVisitorAPITestHelpers.ecID)
        
        module.resetECID()
        XCTAssertNil(module.visitor)
    }

}


class MockAdobeVisitorDiskStorageEmpty: TealiumDiskStorageProtocol {


    init() {

    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {

    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}

class MockAdobeVisitorDiskStoragePopulated: TealiumDiskStorageProtocol {


    init() {

    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {

    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == AdobeVisitor.self else {
            return nil
        }
        
        
        let traveler = TimeTraveler()
                let date = traveler.travel(by: -20)
        
        return AdobeVisitor(experienceCloudID: AdobeVisitorAPITestHelpers.ecID, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: date) as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}

class MockVisitorAPIRefreshFailure: AdobeExperienceCloudIDService {
    var visitor: AdobeVisitor?
    
    func resetNetworkSession() {
        
    }
    
    
    var getNewECIDCallCount = 0
    var getNewECIDAndLinkCallCount = 0
    var linkExistingECIDToKnownIdentifierCallCount = 0
    var refreshECIDCallCount = 0
    var expectation: XCTestExpectation?
    var count: Int?
    
    init(expectation: XCTestExpectation? = nil,
         count: Int? = nil) {
        if let count = count {
            self.count = count - 1
        }
        self.expectation = expectation
    }
    
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
        getNewECIDCallCount += 1
        if (getNewECIDCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func getNewECIDAndLink(customVisitorId: String, dataProviderId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
        getNewECIDAndLinkCallCount += 1
        if (getNewECIDAndLinkCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func linkExistingECIDToKnownIdentifier(customVisitorId: String, dataProviderID: String, experienceCloudId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
    }
    
    func refreshECID(existingECID: String, completion: @escaping AdobeVisitorCompletion) {
        refreshECIDCallCount += 1
        completion(.failure(AdobeVisitorError.invalidJSON))
        if (refreshECIDCallCount == count) {
            self.expectation?.fulfill()
        }
    }
}

class MockVisitorAPIRefreshSuccess: AdobeExperienceCloudIDService {
    var visitor: AdobeVisitor?
    
    func resetNetworkSession() {
        
    }
    
    
    var getNewECIDCallCount = 0
    var getNewECIDAndLinkCallCount = 0
    var linkExistingECIDToKnownIdentifierCallCount = 0
    var refreshECIDCallCount = 0
    var expectation: XCTestExpectation?
    var count: Int?
    
    init(expectation: XCTestExpectation? = nil,
         count: Int? = nil) {
        if let count = count {
            self.count = count - 1
        }
        self.expectation = expectation
    }
    
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
        getNewECIDCallCount += 1
        if (getNewECIDCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func getNewECIDAndLink(customVisitorId: String, dataProviderId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
        getNewECIDAndLinkCallCount += 1
        if (getNewECIDAndLinkCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func linkExistingECIDToKnownIdentifier(customVisitorId: String, dataProviderID: String, experienceCloudId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
    }
    
    func refreshECID(existingECID: String, completion: @escaping AdobeVisitorCompletion) {
        self.expectation?.fulfill()
    }
}

class MockVisitorAPILinkFailure: AdobeExperienceCloudIDService {
    var visitor: AdobeVisitor?
    
    func resetNetworkSession() {
        
    }
    
    
    var getNewECIDCallCount = 0
    var getNewECIDAndLinkCallCount = 0
    var linkExistingECIDToKnownIdentifierCallCount = 0
    var refreshECIDCallCount = 0
    var expectation: XCTestExpectation?
    var count: Int?
    
    init(expectation: XCTestExpectation? = nil,
         count: Int? = nil) {
        if let count = count {
            self.count = count
        }
        self.expectation = expectation
    }
    
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
        getNewECIDCallCount += 1
        if (getNewECIDCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func getNewECIDAndLink(customVisitorId: String, dataProviderId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
        getNewECIDAndLinkCallCount += 1
        if (getNewECIDAndLinkCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func linkExistingECIDToKnownIdentifier(customVisitorId: String, dataProviderID: String, experienceCloudId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
        linkExistingECIDToKnownIdentifierCallCount += 1
        completion?(.failure(AdobeVisitorError.invalidJSON))
        if (linkExistingECIDToKnownIdentifierCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func refreshECID(existingECID: String, completion: @escaping AdobeVisitorCompletion) {

    }
}


class MockVisitorAPIGetAndLinkFailure: AdobeExperienceCloudIDService {
    var visitor: AdobeVisitor?
    
    func resetNetworkSession() {
        
    }
    
    
    var getNewECIDCallCount = 0
    var getNewECIDAndLinkCallCount = 0
    var linkExistingECIDToKnownIdentifierCallCount = 0
    var refreshECIDCallCount = 0
    var expectation: XCTestExpectation?
    var count: Int?
    
    init(expectation: XCTestExpectation? = nil,
         count: Int? = nil) {
        if let count = count {
            self.count = count
        }
        self.expectation = expectation
    }
    
    func getNewECID(completion: @escaping AdobeVisitorCompletion) {
    }
    
    func getNewECIDAndLink(customVisitorId: String, dataProviderId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
        getNewECIDAndLinkCallCount += 1
        completion?(.failure(AdobeVisitorError.invalidJSON))
        if (getNewECIDAndLinkCallCount == count) {
            self.expectation?.fulfill()
        }
    }
    
    func linkExistingECIDToKnownIdentifier(customVisitorId: String, dataProviderID: String, experienceCloudId: String, authState: AdobeVisitorAuthState?, completion: AdobeVisitorCompletion?) {
    }
    
    func refreshECID(existingECID: String, completion: @escaping AdobeVisitorCompletion) {

    }
}

class TimeTraveler {

    private var date = Date()

    func travel(by timeInterval: TimeInterval) -> Date {
        return date.addingTimeInterval(timeInterval)
    }

    func generateDate() -> Date {
        return date
    }
}
