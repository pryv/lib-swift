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
        super.setUp()
        continueAfterFailure = false
        utils = Utils() 
    }

    func testExtractTokenAndEndpointWithToken() {
        let apiEndpoint = "HTTps://token@username.pryv.me" // volonteer to have uppercase to check the regex
        let endpoint = "https://username.pryv.me/"
        let token = "token"
        
        let extractedTuple = utils.extractTokenAndEndpoint(from: apiEndpoint) ?? ("", nil)
        
        XCTAssertEqual(extractedTuple.0, endpoint)
        XCTAssertEqual(extractedTuple.1, token)
    }
    
    func testExtractTokenAndEndpointWithoutToken() {
        let apiEndpoint = "https://username.pryv.me"
        let extractedTuple = utils.extractTokenAndEndpoint(from: apiEndpoint) ?? ("", nil)
        
        XCTAssertEqual(extractedTuple.0, apiEndpoint + "/")
        XCTAssertEqual(extractedTuple.1, nil)
    }
    
    func testExtractTokenAndEnpointFromRandomUrl() {
        let fakeApiEndpoint = "hppt://sjdgkjsbj"
        let extractedTuple = utils.extractTokenAndEndpoint(from: fakeApiEndpoint) ?? ("", nil)
        
        XCTAssertEqual("", extractedTuple.0)
        XCTAssertEqual(nil, extractedTuple.1)
    }
    
    func testBuildPryvApiEndPointWithToken() {
        let apiEndpoint = "https://token@username.pryv.me"
        let endpoint = "https://username.pryv.me/"
        let token = "token"
        
        let builtApiEndpoint = utils.buildPryvApiEndpoint(endpoint: endpoint, token: token)
        
        XCTAssertEqual(builtApiEndpoint, apiEndpoint + "/")
    }
    
    func testBuildPryvApiEndPointWithoutToken() {
        let apiEndpoint = "https://username.pryv.me"
        let builtApiEndpoint = utils.buildPryvApiEndpoint(endpoint: apiEndpoint, token: nil)
        
        XCTAssertEqual(builtApiEndpoint, apiEndpoint + "/")
    }
    
    func testExtractUsernameFromRandomUrl() {
        let fakeApiEndpoint = "hppt://sjdgkjsbj"
        let username = utils.extractUsername(from: fakeApiEndpoint)
        
        XCTAssertNil(username)
    }
    
    func testExtractUsernameWithToken() {
        let apiEndpoint = "https://token@username.pryv.me"
        
        let username = utils.extractUsername(from: apiEndpoint)
        XCTAssertEqual(username, "username")
    }
    
    func testExtractUsernameWithoutToken() {
        let apiEndpoint = "https://username.pryv.me/"
        let username = utils.extractUsername(from: apiEndpoint)

        XCTAssertEqual(username, "username")
    }
    
    func testStringToJson() {
        let string = """
            {
                "key1": "string",
                "key2": 2,
                "key3": {
                    "key3a": 3.0,
                    "key3b": "b"
                }
            }
        """
        let json = utils.stringToJson(string)
        XCTAssertNotNil(json)
        
        let value1 = json!["key1"] as? String
        XCTAssertNotNil(value1)
        XCTAssertEqual(value1!, "string")
        
        let value2 = json!["key2"] as? Int
        XCTAssertNotNil(value2)
        XCTAssertEqual(value2!, 2)
        
        let value3 = json!["key3"] as? Json
        XCTAssertNotNil(value3)
        
        let value3a = value3!["key3a"] as? Double
        XCTAssertNotNil(value3a)
        XCTAssertEqual(value3a!, 3.0)
        
        let value3b = value3!["key3b"] as? String
        XCTAssertNotNil(value3b)
        XCTAssertEqual(value3b!, "b")
    }
    
    func testParseSocketIOURL() {
        let pryvLabURL = "https://chuangzi.pryv.me/chuangzi?auth=ckbthp5bw0003wlpvxn5doicv"
        let ownDomainURL = "https://chuangzi.{domain}/chuangzi?auth=ckbthp5bw0003wlpvxn5doicv"
        let DNSLessURL = "https://host.your-domain.io/chuangzi/chuangzi?auth=ckbthp5bw0003wlpvxn5doicv"
        
        var result = utils.parseSocketIOURL(url: pryvLabURL)
        XCTAssertEqual(result.endpoint, "https://chuangzi.pryv.me/")
        XCTAssertEqual(result.namespace, "/chuangzi")
        XCTAssertEqual(result.connectionParams, ["auth": "ckbthp5bw0003wlpvxn5doicv"])
        
        result = utils.parseSocketIOURL(url: ownDomainURL)
        XCTAssertEqual(result.endpoint, "https://chuangzi.{domain}/")
        XCTAssertEqual(result.namespace, "/chuangzi")
        XCTAssertEqual(result.connectionParams, ["auth": "ckbthp5bw0003wlpvxn5doicv"])
        
        result = utils.parseSocketIOURL(url: DNSLessURL)
        XCTAssertEqual(result.endpoint, "https://host.your-domain.io/")
        XCTAssertEqual(result.namespace, "/chuangzi/chuangzi")
        XCTAssertEqual(result.connectionParams, ["auth": "ckbthp5bw0003wlpvxn5doicv"])
    }
    
}
