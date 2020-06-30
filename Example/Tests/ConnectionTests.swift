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
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testCallBatchCreate() {
        let expectation = self.expectation(description: "call-batch-create")
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
                "modifiedSince": 1546297200.0
            ]
        ]]
        
        let expectation = self.expectation(description: "call-batch-get")
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
        let expectation = self.expectation(description: "add-points-hf")
        
        var error = false
        connection?.addPointsToHFEvent(eventId: "cj3wro4aj80yrx0yqmtm5cfxc", fields: fields, points: points)  { err in
           error = err != nil
           expectation.fulfill()
        }
       
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertFalse(error)
    }
    
    func testStreamedGetEvents() { // big set of events, streaming and chunks for sure
        print("------ Test streamed get events")
        testStreamedGetEvents(limit: 10000)
    }
    
    func testStreamedGetEventsWithDeletions() {
        print("------ Test streamed get events with deletions")
        testStreamedGetEvents(includeDeletions: true) // Note: make sure there are deletion before running this test
    }
    
    func testCreateEvent() {
        let payload: Json = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        let expectation = self.expectation(description: "create-event")
        
        var event: Event? = nil
        var error = false
        connection?.createEventWithFormData(event: payload) { res, err in
            error = err != nil
            event = res
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertFalse(error)
        XCTAssertNotNil(event)

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
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        let expectation = self.expectation(description: "create-event-file")
        
        var error = false
        var event: Event? = nil
        connection?.createEventWithFile(event: payload, filePath: file.absoluteString, mimeType: "application/pdf") { res, err in
            error = err != nil
            event = res
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertNotNil(event)
        XCTAssertFalse(error)

        let attachments = event!["attachments"] as? [Any]
        XCTAssertNotNil(attachments)

        let attachment = attachments![0] as? [String: Any]
        XCTAssertNotNil(attachment)

        let fileName = attachment!["fileName"] as? String
        XCTAssertNotNil(fileName)
        XCTAssertEqual(fileName!, "sample.pdf")

        let type = attachment!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "application/pdf")

        // Note: No test for the function `createEventWithFormData` is done as the function `createEventWithFile` uses already this function.
    }
    
    func testAddFileToEvent() {
        let payload: Event = ["streamIds": ["weight"], "type": "mass/kg", "content": 90]
        let expectationCreate = self.expectation(description: "create-event")
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        
        var event: Event? = nil
        connection?.createEventWithFormData(event: payload) { res, _ in
            event = res
            expectationCreate.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNotNil(event)
        
        let eventId = event!["id"] as? String
        XCTAssertNotNil(eventId)
        
        var error = false
        let expectationAddFile = self.expectation(description: "add-file-event")
        connection?.addFileToEvent(eventId: eventId!, filePath: file.absoluteString, mimeType: "application/pdf") { res, err in
            error = err != nil
            event = res
            expectationAddFile.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertFalse(error)
        XCTAssertNotNil(event)
        
        let attachments = event!["attachments"] as? [Any]
        XCTAssertNotNil(attachments)
        
        let attachment = attachments![0] as? [String: Any]
        XCTAssertNotNil(attachment)
        
        let fileName = attachment!["fileName"] as? String
        XCTAssertNotNil(fileName)
        XCTAssertEqual(fileName!, "sample.pdf")
        
        let type = attachment!["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "application/pdf")
    }
    
    func testGetImagePreview() {
        let apiEndpoint = "https://token@username.pryv.me/"
        let expectedData = Bundle(for: ConnectionTests.self).url(forResource: "corona", withExtension: "jpg")!.dataRepresentation
        let mockGet = Mock(url: URL(string: apiEndpoint + "previews/events/eventId?w=256&h=256&auth=token")!, dataType: .imagePNG, statusCode: 200, data: [.get: expectedData])
        mockGet.register()
        
        let c = Connection(apiEndpoint: apiEndpoint)
        let data = c.getImagePreview(eventId: "eventId")
        XCTAssertEqual(data, expectedData)
    }
    
    private func testStreamedGetEvents(includeDeletions: Bool = false, limit: Int = 20, timeout: Double = 15.0) {
        let expectation = self.expectation(description: "streaming")
        
        var error = false
        var eventsCount = 0
        var eventDeletionsCount = 0
        var meta: Json? = nil
        var params: Json = ["includeDeletions": includeDeletions, "limit": limit]
        if includeDeletions {
            params["modifiedSince"] = 1592837799.925
        }
        
        connection?.getEventsStreamed(queryParams: params, forEachEvent: { event in print(event) ; return }) { result in
            if let count = result["eventsCount"] as? Int, let metaData = result["meta"] as? Json {
                eventsCount = count
                meta = metaData
                print("meta: " + String(describing: meta))
                if includeDeletions {
                    if let delCount = result["eventDeletionsCount"] as? Int {
                        eventDeletionsCount = delCount
                        expectation.fulfill()
                    } else {
                        error = true
                        expectation.fulfill()
                    }
                } else {
                    expectation.fulfill()
                }
            } else {
                error = true
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertFalse(error)
        XCTAssertEqual(meta?.count, 3)
        if includeDeletions {
            XCTAssertGreaterThan(eventsCount, 0)
            XCTAssertGreaterThanOrEqual(eventDeletionsCount, 0)
        } else {
            XCTAssertEqual(eventsCount, limit)
        }
    }
    
    // Note: the part of connection using socket.io is tested in the [example application](https://github.com/pryv/app-swift-example)
    
}
