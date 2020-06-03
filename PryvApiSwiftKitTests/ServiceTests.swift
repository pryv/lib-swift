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
    
    func testApiEndpoint() {
        let username = "username"
        let token = "token"
        
        let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
        let apiEndpoint = service.apiEndpointFor(username: username, token: token)
        
        XCTAssertEqual(apiEndpoint, "https://token@username.pryv.me/")
    }
}
