//
//  ServiceTests.swift
//  PryvSwiftKitTests
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import Mocker
@testable import Promises
@testable import PryvSwiftKit

class ServiceTests: XCTestCase {
    private let timeout = 5.0
    private let appId = "app-id"
    private let testuser = "testuser"
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

    private var service: Service!

    override func setUp() {
        super.setUp()
        
        Mocker.ignore(URL(string: "https://reg.pryv.me/access")!)
        Mocker.ignore(URL(string: "https://reg.pryv.me/service/info")!)
        Mocker.ignore(URL(string: "https://testuser.pryv.me/auth/login")!)

        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl)
    }

    func testInfoNoCustomization() {
        let serviceInfoPromise = service?.info()
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(serviceInfoPromise?.error)
        XCTAssertNotNil(serviceInfoPromise?.value)
        
        let serviceInfo = serviceInfoPromise?.value
        XCTAssertEqual(serviceInfo?.register, "https://reg.pryv.me/")
        XCTAssertEqual(serviceInfo?.access, "https://access.pryv.me/access/")
        XCTAssertEqual(serviceInfo?.api, "https://{username}.pryv.me/")
        XCTAssertEqual(serviceInfo?.name, "Pryv Lab")
        XCTAssertEqual(serviceInfo?.home, "https://sw.pryv.me")
        XCTAssertEqual(serviceInfo?.eventTypes, "https://pryv.github.io/event-types/flat.json")
    }

    func testInfoCustomized() {
        let customService = Service(pryvServiceInfoUrl: pryvServiceInfoUrl, serviceCustomization: serviceCustomization)
        let serviceInfoPromise = customService.info()
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(serviceInfoPromise.error)
        
        let serviceInfo = serviceInfoPromise.value
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
        let token = "token"
        let builtApiEndpoint = service?.apiEndpointFor(username: testuser, token: token)
        let apiEndpoint = "https://\(token)@\(testuser).pryv.me/"
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(builtApiEndpoint?.error)
        XCTAssertEqual(builtApiEndpoint?.value, apiEndpoint)
    }

    func testLogin() {
        let connection = service?.login(username: testuser, password: testuser, appId: appId, origin: "https://login.pryv.me")
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(connection?.error)
        XCTAssertNotNil(connection?.value)
        XCTAssert((connection?.value)!.getApiEndpoint().contains("@\(testuser).pryv.me/"))
    }

    func testSetUpAuth() {
        let requestedPermissions = [
            [
                "streamId": "diary",
                "level": "read",
                "defaultName": "Journal"
            ],
            [
                "streamId": "position",
                "level": "contribute",
                "defaultName": "Position"
            ]
        ]

        let authPayload: Json = [
            "requestingAppId": appId,
            "requestedPermissions": requestedPermissions,
            "languageCode": "fr"
       ]

        let authUrl = service?.setUpAuth(authSettings: authPayload, stateChangedCallback: { _ in return })
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(authUrl?.error)
        XCTAssertNotNil(authUrl?.value)
        XCTAssert((authUrl?.value)!.contains("https://sw.pryv.me/access/access.html?&pollUrl="))

        // The test for the callback function is done in the [app example](https://github.com/pryv/app-swift-example)
    }
}
