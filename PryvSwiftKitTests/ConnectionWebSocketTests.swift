//
//  ConnectionWebSocketTests.swift
//  PryvSwiftKitTests
//
//  Created by Sara Alemanno on 08.07.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Promises
@testable import PryvSwiftKit

class ConnectionWebSocketTests: XCTestCase {
    private let url = "https://testuser.pryv.me/testuser?auth=ckcbrod5o07441vd3q69hisi3"
    private let apiEndpoint = "https://ckcbrod5o07441vd3q69hisi3@testuser.pryv.me/"
    private let streamId = "lib-swift-test"
    
    private var connectionWebSocket: ConnectionWebSocket!
    private var connection: Connection!
    
    override func setUp() {
        super.setUp()
        connectionWebSocket = ConnectionWebSocket(url: url, log: true)
        connection = Connection(apiEndpoint: apiEndpoint)
    }
    
    func testSubscribeEvent() {
        testNotificationWithoutTimeout(message: .eventsChanged) {
            let apiCall: APICall = [
                "method": "events.create",
                "params": [
                      "streamIds": [
                        "weight"
                      ],
                      "type": "mass/kg",
                      "content": 90
                ]
            ]
            connection.api(APICalls: [apiCall])
                .then { _ in print("created new event") }
                .catch { error in XCTFail() }
        }
    }
    
    func testSubscribeStream() {
        let streamPromise = connection.api(APICalls: [
            [
                "method": "streams.update",
                "params": [
                    "id": streamId,
                    "update": ["name": streamId]
                ]
            ]
        ])
        
        XCTAssert(waitForPromises(timeout: 5.0))
        XCTAssertNotNil(streamPromise.value)
        XCTAssertNil(streamPromise.error)
        
        testNotificationWithoutTimeout(message: .streamsChanged) {
            let apiCall: APICall = [
                "method": "streams.update",
                "params": [
                      "id": streamId,
                      "update": [
                        "name": "test-subscribe-stream-\(UUID().uuidString)"
                    ]
                ]
            ]
            connection.api(APICalls: [apiCall])
                .then { _ in print("updated stream with id \(self.streamId)") }
                .catch { error in XCTFail() }
        }
    }
    
    private func testNotificationWithoutTimeout(message: Message, triggerNotification: () -> ()) {
        let expectation = XCTestExpectation(description: "Receive notification")
        var events = [Event]()

        connectionWebSocket?.subscribe(message: message) { _, _ in
            self.connectionWebSocket?.emit(methodId: "events.get", params: ["sortAscending": true]) { result in
                let dataArray = result as NSArray
                let dictionary = dataArray[1] as! Json
                let newEvents = (dictionary["events"] as! [Event])
                events.append(contentsOf: newEvents)
                expectation.fulfill()
            }
        }
        connectionWebSocket.connect()
        sleep(5)
        triggerNotification()
        wait(for: [expectation], timeout: 15.0)
        XCTAssertFalse(events.isEmpty)
    }
    
    override func tearDown() {
        super.tearDown()
        connectionWebSocket?.disconnect()
    }
}
