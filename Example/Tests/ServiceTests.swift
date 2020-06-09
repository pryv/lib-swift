//
//  ServiceTests.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import Mocker
@testable import PryvApiSwiftKit

class ServiceTests: XCTestCase {
    private let pryvServiceInfoUrl = "https://reg.pryv.me/service/info"
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
    
    private let username = "username"
    private let token = "token"
    private let password = "password"
    
    private var service: Service?
    private var customService: Service?
    
    override func setUp() {
        mockServiceInfo()
        
        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl)
        customService = Service(pryvServiceInfoUrl: pryvServiceInfoUrl, serviceCustomization: serviceCustomization)
    }
    
    func testInfoNoCustomization() {
        let serviceInfo = service?.info()
        XCTAssertNotNil(serviceInfo)
        
        XCTAssertEqual(serviceInfo?.register, "https://reg.pryv.me/")
        XCTAssertEqual(serviceInfo?.access, "https://access.pryv.me/access")
        XCTAssertEqual(serviceInfo?.api, "https://{username}.pryv.me/")
        XCTAssertEqual(serviceInfo?.name, "Pryv Lab")
        XCTAssertEqual(serviceInfo?.home, "https://www.pryv.com")
        XCTAssertEqual(serviceInfo?.support, "https://pryv.com/helpdesk")
        XCTAssertEqual(serviceInfo?.terms, "https://pryv.com/pryv-lab-terms-of-use/")
        XCTAssertEqual(serviceInfo?.eventTypes, "https://api.pryv.com/event-types/flat.json")
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
    
    func testApiEndpoint() {
        let builtApiEndpoint = service?.apiEndpointFor(username: username, token: token)
        let apiEndpoint = "https://token@username.pryv.me/"
        
        XCTAssertEqual(builtApiEndpoint, apiEndpoint)
    }
    
    func testLogin() {
        mockLogin()
        
        let connection = service?.login(username: "username", password: "password", appId: "app-id")
        let apiEndpoint = connection?.getApiEndpoint()
        
        XCTAssertNotNil(apiEndpoint)
        XCTAssertEqual(apiEndpoint, "https://ckay3nllh0002lkpv36t1pkyk@username.pryv.me/")
    }
    
    func testSetUpAuth() {
        mockAuthResponse()
        
        let authPayload = """
        {
            "requestingAppId": "test-app-id",
            "requestedPermissions": [
                {
                    "streamId": "diary",
                    "level": "read",
                    "defaultName": "Journal"
                },
                {
                    "streamId": "position",
                    "level": "contribute",
                    "defaultName": "Position"
                }
            ],
            "languageCode": "fr"
        }
        """
    
        let authUrl = service?.setUpAuth(authPayload: authPayload, stateChangedCallback: { _ in return })
        XCTAssertEqual(authUrl, "https://sw.pryv.me/access/access.html?poll=https://reg.pryv.me/access/6CInm4R2TLaoqtl4")
        
        // The test for the callback function is done in the [app example](https://github.com/pryv/app-swift-example)
    }
    
    private func mockServiceInfo() {
        let mockServiceInfo = Mock(url: URL(string: pryvServiceInfoUrl)!, contentType: .json, statusCode: 200, data: [
            .get: MockedData.serviceInfoResponse
        ])
        Mocker.register(mockServiceInfo)
    }
    
    private func mockLogin() {
        let mockLoginEndpoint = Mock(url: URL(string: "https://username.pryv.me/auth/login")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.loginResponse
        ])
        Mocker.register(mockLoginEndpoint)
    }
    
    private func mockAuthResponse() {
        let mockAccessEndpoint = Mock(url: URL(string: "https://reg.pryv.me/access")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.authResponse
        ])
        Mocker.register(mockAccessEndpoint)
    }
}
