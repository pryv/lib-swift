//
//  ServiceTests.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import Mocker
@testable import Promises
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

    private let username = "testuser"
    private let password = "testuser"

    private var service: Service?
    private var customService: Service?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        Mocker.ignore(URL(string: "https://reg.pryv.me/access")!)
        Mocker.ignore(URL(string: "https://reg.pryv.me/service/info")!)
        Mocker.ignore(URL(string: "https://testuser.pryv.me/auth/login")!)

        service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl)
        customService = Service(pryvServiceInfoUrl: pryvServiceInfoUrl, serviceCustomization: serviceCustomization)
    }

    func testInfoNoCustomization() {
        let serviceInfoPromise = service?.info()
        
        XCTAssert(waitForPromises(timeout: 1))
        
        let serviceInfo = serviceInfoPromise?.value
        XCTAssertNil(serviceInfoPromise?.error)

        XCTAssertEqual(serviceInfo?.register, "https://reg.pryv.me/")
        XCTAssertEqual(serviceInfo?.access, "https://access.pryv.me/access/")
        XCTAssertEqual(serviceInfo?.api, "https://{username}.pryv.me/")
        XCTAssertEqual(serviceInfo?.name, "Pryv Lab")
        XCTAssertEqual(serviceInfo?.home, "https://sw.pryv.me")
        XCTAssertEqual(serviceInfo?.support, "https://pryv.com/helpdesk")
        XCTAssertEqual(serviceInfo?.terms, "https://pryv.com/terms-of-use/")
        XCTAssertEqual(serviceInfo?.eventTypes, "https://api.pryv.com/event-types/flat.json")
    }

    func testInfoCustomized() {
        let serviceInfoPromise = customService?.info()
        
        XCTAssert(waitForPromises(timeout: 1))
        
        let serviceInfo = serviceInfoPromise?.value
        XCTAssertNil(serviceInfoPromise?.error)

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
        let builtApiEndpoint = service?.apiEndpointFor(username: username, token: "token")
        let apiEndpoint = "https://token@\(username).pryv.me/"
        
        XCTAssert(waitForPromises(timeout: 1))
        XCTAssertNil(builtApiEndpoint?.error)
        XCTAssertEqual(builtApiEndpoint?.value, apiEndpoint)
    }

    func testLogin() {
        let connection = service?.login(username: username, password: password, appId: "app-id", domain: "pryv.me")
        
        XCTAssert(waitForPromises(timeout: 1))
        XCTAssertNil(connection?.error)
        XCTAssertNotNil(connection?.value)
        XCTAssert((connection?.value)!.getApiEndpoint().contains("@\(username).pryv.me/"))
    }

    func testSetUpAuth() {
        let requestingAppId = "test-app-id"
        let requestedPermissions = [
                ["streamId": "diary", "level": "read", "defaultName": "Journal"],
                ["streamId": "position", "level": "contribute", "defaultName": "Position"]
        ]

        let authPayload: Json = [
            "requestingAppId": requestingAppId,
            "requestedPermissions": requestedPermissions,
            "languageCode": "fr"
       ]

        let authUrl = service?.setUpAuth(authSettings: authPayload, stateChangedCallback: { _ in return })
        
        XCTAssert(waitForPromises(timeout: 1))
        XCTAssertNil(authUrl?.error)
        XCTAssertNotNil(authUrl?.value)
        XCTAssert((authUrl?.value)!.contains("https://sw.pryv.me/access/access.html?&pollUrl="))

        // The test for the callback function is done in the [app example](https://github.com/pryv/app-swift-example)
    }
}
