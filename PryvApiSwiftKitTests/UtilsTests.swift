//
//  UtilsTests.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
@testable import PryvApiSwiftKit

class UtilsTests: XCTestCase {
    
    var utils: Utils!

    override func setUp() {
        utils = Utils() 
    }

    func testExtractTokenAndEndpointWithToken() {
        let apiEndpoint = "https://token@username.pryv.me"
        let endpoint = "https://username.pryv.me/"
        let token = "token"
        
        let extractedTuple = utils.extractTokenAndEndpoint(apiEndpoint: apiEndpoint) ?? ("", nil)
        
        XCTAssertEqual(extractedTuple.0, endpoint)
        XCTAssertEqual(extractedTuple.1, token)
    }
    
    func testExtractTokenAndEndpointWithoutToken() {
        let apiEndpoint = "https://username.pryv.me"
        let extractedTuple = utils.extractTokenAndEndpoint(apiEndpoint: apiEndpoint) ?? ("", nil)
        
        XCTAssertEqual(extractedTuple.0, apiEndpoint + "/")
        XCTAssertEqual(extractedTuple.1, nil)
    }
    
    func testExtractTokenAndEnpointFromRandomUrl() {
        let fakeApiEndpoint = "hppt://sjdgkjsbj"
        let extractedTuple = utils.extractTokenAndEndpoint(apiEndpoint: fakeApiEndpoint) ?? ("", nil)
        
        XCTAssertEqual("", extractedTuple.0)
        XCTAssertEqual(nil, extractedTuple.1)
    }
    
    func testBuildPryvApiEndPointWithToken() {
        let apiEndpoint = "https://token@username.pryv.me"
        let endpoint = "https://username.pryv.me/"
        let token = "token"
        
        let builtApiEndpoint = utils.buildPryvApiEndPoint(endpoint: endpoint, token: token)
        
        XCTAssertEqual(builtApiEndpoint, apiEndpoint + "/")
    }
    
    func testBuildPryvApiEndPointWithoutToken() {
        let apiEndpoint = "https://username.pryv.me"
        let builtApiEndpoint = utils.buildPryvApiEndPoint(endpoint: apiEndpoint, token: nil)
        
        XCTAssertEqual(builtApiEndpoint, apiEndpoint + "/")
    }

}
