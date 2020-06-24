//
//  ConnectionTests.swift
//  PryvApiSwiftKit_Tests
//
//  Created by Sara Alemanno on 08.06.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Mocker
import Alamofire
@testable import PryvApiSwiftKit

class ConnectionTests: XCTestCase {
    
    private let apiEndpoint = "https://token@username.pryv.me/"
    private var c: Connection? // TODO: remove
    
    let connection = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
        .login(username: "testuser", password: "testuser", appId: "lib-swift", domain: "pryv.me")
    private var a: Int?
    
    private let callBatches: [APICall] = [
        [
            "method": "events.create",
            "params": [
                "time": 1591274234.916,
                "streamIds": ["weight"],
                "type": "mass/kg",
                "content": 90
            ]
        ],
        [
            "method": "events.create",
            "params": [
              "time": 1385046854.282,
              "streamIds": ["weight"],
              "type": "mass/kg",
              "content": 120
            ]
        ]
    ]
        
    private let eventId = MockedData.eventId
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        c = Connection(apiEndpoint: apiEndpoint)
    }
    
    func testCallBatchCreate() {
        let expectation = self.expectation(description: "call-batch")
        var events = [Event]()
        var results: [Json]? = nil
        var error = false
        connection?.api(APICalls: callBatches, handleResults: [0: { result in self.a = 2 }]) { res, err in
            error = err != nil
            results = res
            if error || results == nil {
                expectation.fulfill()
            } else {
                for result in results! {
                    if let json = result as? [String: Event] {
                        error = error && json["error"] != nil
                        if let event = json["event"] {
                            events.append(event)
                        }
                    }
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertFalse(error)
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        
        XCTAssertEqual(events.count, 2)

        let event0 = events[0]
        XCTAssertNotNil(event0)

        let time = event0["time"] as? Double
        XCTAssertNotNil(time)
        XCTAssertEqual(time!, 1591274234.916)

        let streamIds = event0["streamIds"] as? [String]
        XCTAssertNotNil(streamIds)
        XCTAssertEqual(streamIds!, ["weight"])

        let streamId = event0["streamId"] as? String
        XCTAssertNotNil(streamId)
        XCTAssertEqual(streamId!, "weight")

        let type = event0["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "mass/kg")

        let content = event0["content"] as? Int
        XCTAssertNotNil(content)
        XCTAssertEqual(content!, 90)
        
        let event1 = events[1]
        XCTAssertNotNil(event1)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, 2)
    }
    
    func testCallBatchGet() {
        let apiCalls: [APICall] = [[
            "method": "events.get",
            "params": [
                "includeDeletions": true,
                "modifiedSince": 1592837799.925
            ]
        ]]
        
        let expectation = self.expectation(description: "call-batch-deletion")
        var results: [Json]? = nil
        var error = false
        var events = [Event]()
        connection?.api(APICalls: apiCalls) { res, err in
            error = err != nil
            results = res
            if error || results == nil {
                expectation.fulfill()
            } else {
            
                for result in results! {
                    if let json = result as? [String: [Event]] {
                        let error = json["error"]
                        XCTAssertNil(error)
                        
                        events.append(contentsOf: json["events"] ?? [Event]())
                        events.append(contentsOf: json["eventDeletions"] ?? [Event]())
                    }
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertFalse(error)
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        
        XCTAssertNotNil(events)
        XCTAssertGreaterThanOrEqual(events.count, 20) // limit + deletions
    }
    
    func testAddPointsToHFEvent() {
        let fields = ["deltaTime", "latitude", "longitude", "altitude"]
        let points = [[0, 10.2, 11.2, 500], [1, 10.2, 11.2, 510], [2, 10.2, 11.2, 520]]
        
        let expectedParameters: Json = [
            "format": "flatJSON",
            "fields": fields,
            "points": points
        ]
        mockHFEvent(expectedParameters: expectedParameters)
        
        c?.addPointsToHFEvent(eventId: eventId, fields: fields, points: points)
        
        // Note: as the function `addPointsToHFEvent` does not return anything, we cannot check its correctness. We will only check that it does not raise an exception; otherwise this test will fail
    }
    
    func testCreateEvent() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        mockCreateEventWithAttachment(expectedParameters: payload)
        
        let event = c?.createEventWithFormData(event: payload)
        XCTAssertNotNil(event)

        let time = event!["time"] as? Double
        XCTAssertNotNil(time)
        XCTAssertEqual(time!, 1591274234.916)

        let streamIds = event!["streamIds"] as? [String]
        XCTAssertNotNil(streamIds)
        XCTAssertEqual(streamIds!, ["weight"])

        let streamId = event!["streamId"] as? String
        XCTAssertNotNil(streamId)
        XCTAssertEqual(streamId!, "weight")

        let type = event!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "mass/kg")

        let content = event!["content"] as? Int
        XCTAssertNotNil(content)
        XCTAssertEqual(content!, 90)
    }
    
    func testCreateEventWithFile() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        mockCreateEventWithAttachment(expectedParameters: payload)
        
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        let event = c?.createEventWithFile(event: payload, filePath: file.absoluteString, mimeType: "application/pdf")
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
        XCTAssertEqual(fileName!, "sample.pdf")
        
        let type = attachment!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "application/pdf")
        
        let size = attachment!["size"] as? Int
        XCTAssertNotNil(size)
        XCTAssertEqual(size!, 111)
        
        let readToken = attachment!["readToken"] as? String
        XCTAssertNotNil(readToken)
        XCTAssertEqual(readToken!, "ckb6fn2p9000s4y0slij89se5-JGZ6xx1vFDvSFsCxdoO4ptM7gc8")
        
        // Note: No test for the function `createEventWithFormData` is done as the function `createEventWithFile` uses already this function.
    }
    
    func testAddFileToEvent() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        mockCreateEventWithAttachment(expectedParameters: payload)
        
        var event = c?.createEventWithFormData(event: payload)
        XCTAssertNotNil(event)
        
        let eventId = event!["id"] as? String
        XCTAssertNotNil(eventId)
        
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        event = c?.addFileToEvent(eventId: eventId!, filePath: file.absoluteString, mimeType: "application/pdf")
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
        XCTAssertEqual(fileName!, "sample.pdf")
        
        let type = attachment!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "application/pdf")
        
        let size = attachment!["size"] as? Int
        XCTAssertNotNil(size)
        XCTAssertEqual(size!, 111)
        
        let readToken = attachment!["readToken"] as? String
        XCTAssertNotNil(readToken)
        XCTAssertEqual(readToken!, "ckb6fn2p9000s4y0slij89se5-JGZ6xx1vFDvSFsCxdoO4ptM7gc8")
    }
    
    func testGetImagePreview() {
        mockImagePreview()
        let data = c?.getImagePreview(eventId: "eventId")
        XCTAssertEqual(data, MockedData.imagePreview)
    }
    
    private func mockImagePreview() {
        let mockGet = Mock(url: URL(string: apiEndpoint + "previews/events/eventId?w=256&h=256&auth=token")!, dataType: .imagePNG, statusCode: 200, data: [
            .get: MockedData.imagePreview
        ])
        mockGet.register()
    }

    private func mockCreateEventWithAttachment(expectedParameters: [String: Any]) {
        var mockCreateEvent = Mock(url: URL(string: apiEndpoint + "events")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.createEventResponse
        ])
        let mockAddAttachment = Mock(url: URL(string: apiEndpoint + "events/\(eventId)")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.addAttachmentResponse
        ])
        
        mockCreateEvent.onRequest = { request, postBodyArguments in
            XCTAssertEqual(request.url, mockCreateEvent.request.url)
            XCTAssertNotNil(postBodyArguments)
            
            let type = postBodyArguments!["type"] as? String
            XCTAssertNotNil(type)
            XCTAssertEqual(type, expectedParameters["type"] as? String)
            
            let content = postBodyArguments!["content"] as? Int
            XCTAssertNotNil(content)
            XCTAssertEqual(content, expectedParameters["content"] as? Int)
            
            let streamIds = postBodyArguments!["streamIds"] as? [String]
            XCTAssertNotNil(streamIds)
            XCTAssertEqual(streamIds, expectedParameters["streamIds"] as? [String])
        }
        
        mockCreateEvent.register()
        mockAddAttachment.register()
    }
    
    private func mockHFEvent(expectedParameters: [String: Any]) {
        var mockAddPointsToHFEvent = Mock(url: URL(string: apiEndpoint + "events/\(eventId)/series")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.okResponse
        ])
        
        mockAddPointsToHFEvent.onRequest = { request, postBodyArguments in
            XCTAssertEqual(request.url, mockAddPointsToHFEvent.request.url)
            XCTAssertNotNil(postBodyArguments)
            
            let format = postBodyArguments!["format"] as? String
            XCTAssertNotNil(format)
            XCTAssertEqual(format, expectedParameters["format"] as? String)
            
            let fields = postBodyArguments!["fields"] as? [String]
            XCTAssertNotNil(fields)
            XCTAssertEqual(fields, expectedParameters["fields"] as? [String])
            
            let points = postBodyArguments!["points"] as? [[Double]]
            XCTAssertNotNil(points)
            XCTAssertEqual(points, expectedParameters["points"] as? [[Double]])
        }
        
        mockAddPointsToHFEvent.register()
    }
    
}
