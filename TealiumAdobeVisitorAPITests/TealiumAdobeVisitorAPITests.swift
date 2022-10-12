//
//  TealiumAdobeVisitorAPITests.swift
//  TealiumAdobeVisitorAPITests
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumAdobeVisitorAPI

struct AdobeVisitorAPITestHelpers {

    static let ecID = "12345"
    static let adobeOrgId = "ABC123@AdobeOrg"
    static let testVisitorId = "test@tealium.com"

    static let testDPID = "dpid"
    static let userID = "someuser@tealium.com"
    static let authstate = AdobeVisitorAuthState.authenticated

    public static func getTestJSONData() -> Data? {
        let dictionary = [
            "d_mid": ecID,
            "dcs_region": "6",
            "id_sync_ttl": "604800",
            "d_blob": "wxyz5432"
        ]
        if let json = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            return json
        }
        return nil
    }
    
    public static var testJSONDataEmptyECID: Data? {
        let dictionary = [
            "dcs_region": "6",
            "id_sync_ttl": "604800",
            "d_blob": "wxyz5432"
        ]
        if let json = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            return json
        }
        return nil
    }
}

class MockNetworkSessionNeverRespond: NetworkSession {
    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void) {
    }

    func invalidateAndClose() {}
    
    func reset() {
        
    }
}

class MockNetworkSessionVisitorSuccess: NetworkSession {
    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void) {
        if let url = request.url,
           let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [:]),
           let data = AdobeVisitorAPITestHelpers.getTestJSONData() {
            completionHandler(.success((response, data)))
        }
    }

    func invalidateAndClose() {}
    
    func reset() {
        
    }
}


class MockNetworkSessionVisitorSuccessEmptyECID: NetworkSession {
    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void) {
        if let url = request.url,
           let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [:]),
           let data = AdobeVisitorAPITestHelpers.testJSONDataEmptyECID {
            completionHandler(.success((response, data)))
        }
    }

    func invalidateAndClose() {}
    
    func reset() {
        
    }
}

class MockNetworkSessionVisitorFailure: NetworkSession {
    var expectation: XCTestExpectation?
    init(expectation: XCTestExpectation? = nil) {
        self.expectation = expectation
    }
    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void) {
        expectation?.fulfill()
        completionHandler(.failure(AdobeVisitorError.missingOrgID))
    }

    func invalidateAndClose() {}
    
    func reset() {
        
    }
}

class TealiumAdobeVisitorAPITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    var adobeVisitorAPI: AdobeVisitorAPI {
        AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorSuccess(),
                                              retryManager: retryManager,
                                              adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    }
    
    func testGenerateECID() {

        let expectation = self.expectation(description: "Generate New ECID")

        let adobeVisitorAPI = adobeVisitorAPI

        adobeVisitorAPI.getNewECID() { result in
            switch result {
            case .success(let result):
                XCTAssertEqual(result.experienceCloudID, AdobeVisitorAPITestHelpers.ecID, "Unexpected mismatch in Adobe ECIDs")
                expectation.fulfill()
            case .failure:
                XCTFail("Unexpected failure when retrieving ECID")
            }
        }

        self.wait(for: [expectation], timeout: 10.0)

    }

    func testLinkKnownID() {

        let expectation = self.expectation(description: "Link Known ID")

        let adobeVisitorAPI = adobeVisitorAPI

        adobeVisitorAPI.linkExistingECIDToKnownIdentifier(
                customVisitorId: AdobeVisitorAPITestHelpers.testVisitorId,
                dataProviderID: AdobeVisitorAPITestHelpers.testDPID,
                experienceCloudId: AdobeVisitorAPITestHelpers.ecID,
                authState: AdobeVisitorAPITestHelpers.authstate) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpected failure when retrieving ECID: \(error.localizedDescription)")
            }
        }

        self.wait(for: [expectation], timeout: 10.0)
    }

    func testGenerateCIDParam() {
        let adobeVisitorAPI = adobeVisitorAPI
        let expectedCID = "\(AdobeVisitorAPITestHelpers.testDPID)%01\(AdobeVisitorAPITestHelpers.userID)%01\(AdobeVisitorAPITestHelpers.authstate.rawValue.description)"

        let cid = adobeVisitorAPI.generateCID(dataProviderId: AdobeVisitorAPITestHelpers.testDPID, customVisitorId: AdobeVisitorAPITestHelpers.userID, authState: AdobeVisitorAPITestHelpers.authstate)
        XCTAssertEqual(cid, expectedCID, "CID parameters do not match")
    }
    
    func testRefreshECID() {
        let expectation = self.expectation(description: "Refresh")

        let adobeVisitorAPI = adobeVisitorAPI

        adobeVisitorAPI.refreshECID(
                existingECID: AdobeVisitorAPITestHelpers.testVisitorId) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure (let error):
                XCTFail("Unexpected failure when retrieving ECID: \(error.localizedDescription)")
            }
        }

        self.wait(for: [expectation], timeout: 10.0)
    }

    func testFailingCallRetries() {
        
        let expectation = self.expectation(description: "Retries 5 times + the first call")
        expectation.expectedFulfillmentCount = retryManager.maxRetries + 1

        let adobeVisitorAPI = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorFailure(expectation: expectation),
                                              retryManager: retryManager,
                                              adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
        adobeVisitorAPI.sendRequest(url: URL(string: "www.example.com")!, completion: nil)
        
        self.wait(for: [expectation], timeout: 10.0)
    }

}
