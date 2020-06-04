//
//  ServiceTests.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
@testable import PryvApiSwiftKit

class ServiceTests: XCTestCase {
    private let pryvServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let username = "username"
    private let token = "token"
    private let password = "password"
    private let apiEndpoint = "https://token@username.pryv.me/"
    private let expectedServiceInfo = [
        "register": "https://reg.pryv.me",
        "access": "https://access.pryv.me/access",
        "api": "https://{username}.pryv.me/",
        "name": "Pryv Lab",
        "home": "https://www.pryv.com",
        "support": "https://pryv.com/helpdesk",
        "terms": "https://pryv.com/pryv-lab-terms-of-use/",
        "eventTypes": "https://api.pryv.com/event-types/flat.json"
    ]
    private let serviceCustomization = [
        "register": "https://reg.pryv2.me",
        "access": "https://access.pryv2.me/access",
        "api": "https://{username}.pryv2.me/",
        "name": "Pryv 2 Lab",
        "home": "https://www.pryv2.com",
        "support": "https://pryv2.com/helpdesk",
        "terms": "https://pryv2.com/pryv-lab-terms-of-use/",
        "eventTypes": "https://api.pryv2.com/event-types/flat.json"
    ]
    
    private var service: Service?
    private var customService: Service?
    
    override func setUp() {
        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl)
        customService = Service(pryvServiceInfoUrl: pryvServiceInfoUrl, serviceCustomization: serviceCustomization)
    }
    
    // FIXME: no test pass => use mocking
    
    func testApiEndpoint() {
        let builtApiEndpoint = service?.apiEndpointFor(username: username, token: token)
        XCTAssertEqual(builtApiEndpoint, apiEndpoint)
    }
    
    func testInfoNoCustomization() {
        let serviceInfo = service?.info()
        XCTAssertNotNil(serviceInfo)
        
        XCTAssertEqual(serviceInfo?.register, expectedServiceInfo["register"])
        XCTAssertEqual(serviceInfo?.access, expectedServiceInfo["access"])
        XCTAssertEqual(serviceInfo?.api, expectedServiceInfo["api"])
        XCTAssertEqual(serviceInfo?.name, expectedServiceInfo["name"])
        XCTAssertEqual(serviceInfo?.home, expectedServiceInfo["home"])
        XCTAssertEqual(serviceInfo?.support, expectedServiceInfo["support"])
        XCTAssertEqual(serviceInfo?.terms, expectedServiceInfo["terms"])
        XCTAssertEqual(serviceInfo?.eventTypes, expectedServiceInfo["eventTypes"])
    }
    
    func testInfoCustomized() {
        let serviceInfo = customService?.info()
        XCTAssertNotNil(serviceInfo)
        
        XCTAssertEqual(serviceInfo?.register, serviceCustomization["register"])
        XCTAssertEqual(serviceInfo?.access, serviceCustomization["access"])
        XCTAssertEqual(serviceInfo?.api, serviceCustomization["api"])
        XCTAssertEqual(serviceInfo?.name, serviceCustomization["name"])
        XCTAssertEqual(serviceInfo?.home, serviceCustomization["home"])
        XCTAssertEqual(serviceInfo?.support, serviceCustomization["support"])
        XCTAssertEqual(serviceInfo?.terms, serviceCustomization["terms"])
        XCTAssertEqual(serviceInfo?.eventTypes, serviceCustomization["eventTypes"])
    }
    
    func testLogin() {
        let connection = service?.login(username: "username", password: "password", appId: "app-id")
        let apiEndpoint = connection?.getApiEndpoint()
        
        XCTAssertNotNil(apiEndpoint)
        XCTAssertEqual(apiEndpoint, "https://token@username.pryv.me/")
    }
}
