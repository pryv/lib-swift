//
//  ConnectionTests.swift
//  PryvApiSwiftKit_Tests
//
//  Created by Sara Alemanno on 08.06.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Mocker
@testable import PryvApiSwiftKit

class ConnectionTests: XCTestCase {
    
    private let apiEndpoint = "https://token@username.pryv.me/"
    private var connection: Connection?
    private var a: String?
    
    private let callBatches = """
        [
          {
            "method": "events.create",
            "params": {
              "time": 1385046854.282,
              "streamIds": [
                "heart"
              ],
              "type": "frequency/bpm",
              "content": 90
            }
          },
          {
            "method": "events.create",
            "params": {
              "time": 1385046854.282,
              "streamIds": [
                "systolic"
              ],
              "type": "pressure/mmhg",
              "content": 120
            }
          }
        ]
    """
    private let eventId = "eventId"
    
    override func setUp() {
        
        connection = Connection(apiEndpoint: apiEndpoint)
        mockResponses()
    }
    
    func testCallBatch() {
        let events = connection?.api(APICalls: callBatches)
    
        let event0 = events?[0]
        XCTAssertNotNil(event0)
        
        let id = event0!["id"] as? String
        XCTAssertNotNil(id)
        XCTAssertEqual(id!, "ckb0rldt0000tq6pvrahee7gj")
        
        let time = event0!["time"] as? Double
        XCTAssertNotNil(time)
        XCTAssertEqual(time!, 1385046854.282)
        
        let streamId = event0!["streamId"] as? String
        XCTAssertNotNil(streamId)
        XCTAssertEqual(streamId!, "heart")
        
        let tags = event0!["tags"] as? [String]
        XCTAssertNotNil(tags)
        XCTAssert(tags!.isEmpty)
        
        let type = event0!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "frequency/bpm")
        
        let content = event0!["content"] as? Int
        XCTAssertNotNil(content)
        XCTAssertEqual(content!, 90)
        
        let created = event0!["created"] as? Double
        XCTAssertNotNil(created)
        XCTAssertEqual(created!, 1591274234.916)
        
        let createdBy = event0!["createdBy"] as? String
        XCTAssertNotNil(createdBy)
        XCTAssertEqual(createdBy!, "ckb0rldr90001q6pv8zymgvpr")
        
        let modified = event0!["modified"] as? Double
        XCTAssertNotNil(modified)
        XCTAssertEqual(modified!, 1591274234.916)
        
        let modifiedBy = event0!["modifiedBy"] as? String
        XCTAssertNotNil(modifiedBy)
        XCTAssertEqual(modifiedBy!, "ckb0rldr90001q6pv8zymgvpr")
        
        let event1 = events?[1]
        XCTAssertNotNil(event1)
    }
    
    func testCallBatchCallback() {
        let _ = connection?.api(APICalls: callBatches, handleResults: [0: changeA])
        
        XCTAssertNotNil(a)
        XCTAssertEqual(a, "ckb0rldt0000tq6pvrahee7gj")
        
        // Note: this test only checks that a simple callback is executed. A more precise test for call batch is `testCallBatch`
    }
    
    func testAddPointsToHFEvent() {
        let fields = ["deltaTime", "latitude", "longitude", "altitude" ]
        let points = [[0, 10.2, 11.2, 500], [1, 10.2, 11.2, 510], [2, 10.2, 11.2, 520]]
        
        connection?.addPointsToHFEvent(eventId: eventId, fields: fields, points: points)
        
        // Note: as the function `addPointsToHFEvent` does not return anything, we cannot check its correctness. We will only check that it does not raise an exception; otherwise this test will fail
    }
    
    private func changeA(event: [String : Any]) -> () {
        a = event["id"] as? String
    }

    private func mockResponses() {
        let mockCallBatch = Mock(url: URL(string: apiEndpoint)!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        let mockAddPointsToHFEvent = Mock(url: URL(string: apiEndpoint + "/events/\(eventId)/series")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.okResponse
        ])
        
        Mocker.register(mockCallBatch)
        Mocker.register(mockAddPointsToHFEvent)
    }
}
