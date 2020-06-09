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
    }
    
    func testCallBatch() {
        mockCallBatch()
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
        mockCallBatch()
        let _ = connection?.api(APICalls: callBatches, handleResults: [0: { event in
            self.a = event["id"] as? String
        }])
        
        XCTAssertNotNil(a)
        XCTAssertEqual(a, "ckb0rldt0000tq6pvrahee7gj")
        
        // Note: this test only checks that a simple callback is executed. A more precise test for call batch is `testCallBatch`
    }
    
    func testAddPointsToHFEvent() {
        mockHFEvent()
        
        let fields = ["deltaTime", "latitude", "longitude", "altitude" ]
        let points = [[0, 10.2, 11.2, 500], [1, 10.2, 11.2, 510], [2, 10.2, 11.2, 520]]
        
        connection?.addPointsToHFEvent(eventId: eventId, fields: fields, points: points)
        
        // Note: as the function `addPointsToHFEvent` does not return anything, we cannot check its correctness. We will only check that it does not raise an exception; otherwise this test will fail
    }
    
    func testCreateEvent() { 
        mockCreateEventWithAttachment()
        
        let payload: [String: Any] = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        let event = connection?.createEventWithFormData(event: payload, parameters: nil, files: nil)
        
        XCTAssertNotNil(event)

        let id = event!["id"] as? String
        XCTAssertNotNil(id)
        XCTAssertEqual(id!, eventId)

        let time = event!["time"] as? Double
        XCTAssertNotNil(time)
        XCTAssertEqual(time!, 1591274234.916)

        let streamIds = event!["streamIds"] as? [String]
        XCTAssertNotNil(streamIds)
        XCTAssertEqual(streamIds!, ["weight"])

        let streamId = event!["streamId"] as? String
        XCTAssertNotNil(streamId)
        XCTAssertEqual(streamId!, "weight")

        let tags = event!["tags"] as? [String]
        XCTAssertNotNil(tags)
        XCTAssertTrue(tags!.isEmpty)

        let type = event!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "mass/kg")

        let content = event!["content"] as? Int
        XCTAssertNotNil(content)
        XCTAssertEqual(content!, 90)

        let created = event!["created"] as? Double
        XCTAssertNotNil(created)
        XCTAssertEqual(created!, 1591274234.916)

        let createdBy = event!["createdBy"] as? String
        XCTAssertNotNil(createdBy)
        XCTAssertEqual(createdBy!, "ckb0rldr90001q6pv8zymgvpr")

        let modified = event!["modified"] as? Double
        XCTAssertNotNil(modified)
        XCTAssertEqual(modified!, 1591274234.916)

        let modifiedBy = event!["modifiedBy"] as? String
        XCTAssertNotNil(modifiedBy)
        XCTAssertEqual(modifiedBy!, "ckb0rldr90001q6pv8zymgvpr")
    }
    
    func testCreateEventWithFormData() {
        mockCreateEventWithAttachment()
        
        let parameters = [String: String]()
        let files = [Media]()
        
        let payload: [String: Any] = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        let event = connection?.createEventWithFormData(event: payload, parameters: parameters, files: files)
        XCTAssertNotNil(event)
        
        let attachments = event!["attachments"] as? [Any]
        XCTAssertNotNil(attachments)
        
        let attachment = attachments![0] as? [String: Any]
        XCTAssertNotNil(attachment)
        
        let id = attachment!["id"] as? String
        XCTAssertNotNil(id)
        XCTAssertEqual(id!, "ckb6fn2p9000r4y0s51ve4cx8")
        
        let fileName = attachment!["fileName"] as? String
        XCTAssertNotNil(fileName)
        XCTAssertEqual(fileName!, "travel-expense.jpg")
        
        let type = attachment!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "image/jpeg")
        
        let size = attachment!["size"] as? Int
        XCTAssertNotNil(size)
        XCTAssertEqual(size!, 111)
        
        let readToken = attachment!["readToken"] as? String
        XCTAssertNotNil(readToken)
        XCTAssertEqual(readToken!, "ckb6fn2p9000s4y0slij89se5-JGZ6xx1vFDvSFsCxdoO4ptM7gc8")
        
        // Note: The test for the function `createEventWithFile` is done in the [app example](https://github.com/pryv/app-swift-example)
    }

    private func mockCreateEventWithAttachment() {
        let mockCreateEvent = Mock(url: URL(string: apiEndpoint + "events")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.createEventResponse
        ])
        let mockAddAttachment = Mock(url: URL(string: apiEndpoint + "events/\(eventId)")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.addAttachmentResponse
        ])
        
        Mocker.register(mockCreateEvent)
        Mocker.register(mockAddAttachment)
    }
    
    private func mockCallBatch() {
        let mockCallBatch = Mock(url: URL(string: apiEndpoint)!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        
        Mocker.register(mockCallBatch)
    }
    
    private func mockHFEvent() {
        let mockAddPointsToHFEvent = Mock(url: URL(string: apiEndpoint + "events/\(eventId)/series")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.okResponse
        ])
        
        Mocker.register(mockAddPointsToHFEvent)
    }
}
