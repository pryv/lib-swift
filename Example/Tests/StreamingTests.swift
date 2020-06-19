//
//  StreamingTests.swift
//  PryvApiSwiftKit_Tests
//
//  Created by Sara Alemanno on 19.06.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Mocker
@testable import PryvApiSwiftKit

// Note: this test is not placed in `ConnectionTests` to avoid using mocking and testing the streaming of the `events.get` method
class StreamingTests: XCTestCase {
    
    override func setUp() {
        let ignoredURLs = [
            URL(string: "https://testuser.pryv.me/auth/login")!,
            URL(string: "https://reg.pryv.me/service/info")!
        ]
        ignoredURLs.forEach { url in Mocker.ignore(url) }
    }
    
    func testStreamedGetEventsSmallBatch() { // small set of events, very little streaming
        testStreamedGetEvents(limit: 30)
    }
    
    func testStreamedGetEventsMediumBatch() { // medium set of events, streaming and chunks for sure
        testStreamedGetEvents(limit: 100)
    }
    
    func testStreamedGetEventsBigBatch() { // big set of events, streaming and chunks for sure
        testStreamedGetEvents(limit: 10000) 
    }
    
    private func testStreamedGetEvents(limit: Int) {
        let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
        let conn = service.login(username: "testuser", password: "testuser", appId: "lib-swift", domain: "pryv.me")
        
        let params = ["limit": limit]
        conn?.getEventsStreamed(queryParams: params, forEachEvent: { _ in /*print($0) ; */ return }) { result in
            switch result {
            case .failure(_): return
            case .success(let message): print(message)
            }
        }
        
        sleep(2)
    }
}
