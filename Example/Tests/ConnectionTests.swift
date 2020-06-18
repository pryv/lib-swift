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
              "streamIds": ["systolic"],
              "type": "pressure/mmhg",
              "content": 120
            ]
        ]
    ]
        
    private let eventId = MockedData.eventId
    
    override func setUp() {
        connection = Connection(apiEndpoint: apiEndpoint)
    }
    
    func testCallBatch() {
        mockCallBatch(expectedParameters: callBatches)
        let events = connection?.api(APICalls: callBatches)
    
        let event0 = events?[0]
        checkEvent(event0)
        
        let event1 = events?[1]
        XCTAssertNotNil(event1)
    }
    
    func testCallBatchCallback() {
        mockCallBatch(expectedParameters: callBatches)
        let _ = connection?.api(APICalls: callBatches, handleResults: [0: { event in
            self.a = event["id"] as? String
        }])
        
        XCTAssertNotNil(a)
        XCTAssertEqual(a, eventId)
        
        // Note: this test only checks that a simple callback is executed. A more precise test for call batch is `testCallBatch`
    }
    
    func testGetEvents() {
        let params = ["limit": 3]
        mockGetEvents(expectedParameters: params)
        
        var events = [Event]()
        connection?.getEventsStreamed(queryParams: params) { event in
            events.append(event)
        }
        
        XCTAssertEqual(events.count, 3)
        checkEvent(events.first)
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
        
        connection?.addPointsToHFEvent(eventId: eventId, fields: fields, points: points)
        
        // Note: as the function `addPointsToHFEvent` does not return anything, we cannot check its correctness. We will only check that it does not raise an exception; otherwise this test will fail
    }
    
    func testCreateEvent() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        mockCreateEventWithAttachment(expectedParameters: payload)
        
        let event = connection?.createEventWithFormData(event: payload)
        
        checkEvent(event)
    }
    
    func testCreateEventWithFile() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        mockCreateEventWithAttachment(expectedParameters: payload)
        
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        let event = connection?.createEventWithFile(event: payload, filePath: file.absoluteString, mimeType: "application/pdf")
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
        
        var event = connection?.createEventWithFormData(event: payload)
        XCTAssertNotNil(event)
        
        let eventId = event!["id"] as? String
        XCTAssertNotNil(eventId)
        
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        event = connection?.addFileToEvent(eventId: eventId!, filePath: file.absoluteString, mimeType: "application/pdf")
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
    
    private func mockCallBatch(expectedParameters: [[String: Any]]) {
        let mockCallBatch = Mock(url: URL(string: apiEndpoint)!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        mockCallBatch.register()
        
        /*
            # Note
            The Mocker library does not access arrays, but only dictionnaries as `postBodyArguments`.
            As the callbatch request sends an array of dictionnaries, the `postBodyArguments` are `nil`.
            Therefore, it is not possible to assert that the body of the request is correct in this case.
            We assumed the creation of event/get of events are similar, which is why this mock does not check the `postBodyArguments`.
        */
    }
    
    private func mockGetEvents(expectedParameters: Json) {
        var mockGetEvents = Mock(url: URL(string: apiEndpoint + "events")!, dataType: .json, statusCode: 200, data: [
            .get: MockedData.getEventsResponse
        ])
        
        mockGetEvents.onRequest = { request, getBodyArguments in
            XCTAssertEqual(request.url, mockGetEvents.request.url)
            XCTAssertNotNil(getBodyArguments)
            
            let limit = getBodyArguments!["limit"] as? Int
            XCTAssertNotNil(limit)
            XCTAssertEqual(limit, expectedParameters["limit"] as? Int)
        }
        
        mockGetEvents.register()
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
    
    private func checkEvent(_ event: Event?) {
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
}
