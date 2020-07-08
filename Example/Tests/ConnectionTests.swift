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
@testable import Promises

class ConnectionTests: XCTestCase {
    private let timeout = 5.0
    private let streamingTimeout = 15.0
    private let testuser = "testuser"
    private let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    private let callBatches: [APICall] = [
        [
            "method": "events.create",
            "params": [
                "time": 1591274234.916,
                "streamId": "weight",
                "type": "mass/kg",
                "content": 90
            ]
        ],
        [
            "method": "events.create",
            "params": [
                "time": 1385046854.282,
                "streamId": "weight",
                "type": "mass/kg",
                "content": 120
            ]
        ]
    ]
    
    private var connection: Connection!

    override func setUp() {
        super.setUp()
        
        Mocker.ignore(URL(string: "https://testuser.pryv.me/service/info")!)
        Mocker.ignore(URL(string: "https://reg.pryv.me/service/info")!)
        Mocker.ignore(URL(string: "https://testuser.pryv.me/auth/login")!)
        
        let promise = service.login(username: testuser, password: testuser, appId: testuser, origin: "https://login.pryv.me")
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        
        connection = promise.value
    }
    
    func testService() {
        let service = connection?.getService()
        XCTAssertEqual(service, Service(pryvServiceInfoUrl: "https://testuser.pryv.me/service/info"))
    }
    
    func testUsername() {
        let username = connection?.username()
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(username?.error)
        XCTAssertEqual(username?.value, "testuser")
    }

    func testCallBatchCreateEvents() {
        var events = [Event]()
        var a = 0
        let results = connection?.api(APICalls: callBatches, handleResults: [0: { result in a = 2 }])
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(results?.error)
        XCTAssertNotNil(results?.value)
        
        for result in (results?.value)! {
            if let json = result as? [String: Event] {
                if let event = json["event"] {
                    events.append(event)
                }
            }
        }
        
        XCTAssertEqual((results?.value)!.count, 2)
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

    func testCallBatchGetEvents() {
        let apiCalls: [APICall] = [[
            "method": "events.get",
            "params": [
                "includeDeletions": true,
                "modifiedSince": 1546297200.0
            ]
        ]]

        var events = [Event]()
        let results = connection?.api(APICalls: apiCalls)
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(results?.error)
        XCTAssertNotNil(results?.value)

        for result in (results?.value)! {
            if let json = result as? [String: [Event]] {
                let error = json["error"]
                XCTAssertNil(error)

                events.append(contentsOf: json["events"] ?? [Event]())
                events.append(contentsOf: json["eventDeletions"] ?? [Event]())
            }
        }
        
        XCTAssertEqual((results?.value)!.count, 1)

        XCTAssertNotNil(events)
        XCTAssertGreaterThanOrEqual(events.count, 20) // limit + deletions
    }

    func testAddPointsToHFEvent() {
        let fields = ["deltaTime", "latitude", "longitude", "altitude"]
        let points = [[0, 10.2, 11.2, 500], [1, 10.2, 11.2, 510], [2, 10.2, 11.2, 520]]
        
        let hfEvent: Json = [
            "streamIds": [
              "position"
            ],
            "type": "series:position/wgs84"
        ]
        var result: Promise<Json>? = nil
        let _ = connection.createEventWithFormData(event: hfEvent).then { event in
            let eventId = event["id"] as! String
            result = self.connection?.addPointsToHFEvent(eventId: eventId, fields: fields, points: points)
        }
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
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
        let payload: Json = ["streamId": "weight", "type": "mass/kg", "content": 90]
        let result = connection?.createEventWithFormData(event: payload)
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
        
        let event = (result?.value)!

        let streamIds = event["streamIds"] as? [String]
        XCTAssertNotNil(streamIds)
        XCTAssertEqual(streamIds!, ["weight"])

        let streamId = event["streamId"] as? String
        XCTAssertNotNil(streamId)
        XCTAssertEqual(streamId!, "weight")

        let type = event["type"] as? String
        XCTAssertNotNil(type)
        XCTAssertEqual(type!, "mass/kg")

        let content = event["content"] as? Int
        XCTAssertNotNil(content)
        XCTAssertEqual(content!, 90)
    }

    func testCreateEventWithFile() {
        let payload: Event = ["streamId": "weight", "type": "mass/kg", "content": 90]
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        
        let result = connection?.createEventWithFile(event: payload, filePath: file.absoluteString, mimeType: "application/pdf")
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
        
        let event = (result?.value)!

        let attachments = event["attachments"] as? [Any]
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
        let file = Bundle(for: ConnectionTests.self).url(forResource: "sample", withExtension: "pdf")!
        var result = connection?.createEventWithFormData(event: payload)
        
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
        
        var event = (result?.value)!
        let eventId = event["id"] as? String
        XCTAssertNotNil(eventId)
        
        result = connection?.addFileToEvent(eventId: eventId!, filePath: file.absoluteString, mimeType: "application/pdf")
        XCTAssert(waitForPromises(timeout: timeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
        
        event = (result?.value)!

        let attachments = event["attachments"] as? [Any]
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
        let token = "token"
        let apiEndpoint = "https://\(token)@\(testuser).pryv.me/"
        let expectedData = Bundle(for: ConnectionTests.self).url(forResource: "corona", withExtension: "jpg")!.dataRepresentation
        let mockGet = Mock(url: URL(string: apiEndpoint + "previews/events/eventId?w=256&h=256&auth=token")!, dataType: .imagePNG, statusCode: 200, data: [.get: expectedData])
        mockGet.register()

        let data = Connection(apiEndpoint: apiEndpoint).getImagePreview(eventId: "eventId")
        XCTAssertEqual(data, expectedData)
    }

    private func testStreamedGetEvents(includeDeletions: Bool = false, limit: Int = 20) {
        var error = false
        var eventsCount = 0
        var eventDeletionsCount = 0
        var meta: Json? = nil
        var params: Json = ["includeDeletions": includeDeletions, "limit": limit]
        if includeDeletions {
            params["modifiedSince"] = 1592837799.925
        }

        let result = connection?.getEventsStreamed(queryParams: params, forEachEvent: { event in print(event) ; return })
    
        XCTAssert(waitForPromises(timeout: streamingTimeout))
        XCTAssertNil(result?.error)
        XCTAssertNotNil(result?.value)
        
        let value = (result?.value)!
        
        if let count = value["eventsCount"] as? Int, let metaData = value["meta"] as? Json {
            eventsCount = count
            meta = metaData
            print("meta: " + String(describing: meta))
            if includeDeletions {
                if let delCount = value["eventDeletionsCount"] as? Int {
                    eventDeletionsCount = delCount
                } else {
                    error = true
                }
            }
        } else {
            error = true
        }

        XCTAssertFalse(error)
        XCTAssertEqual(meta?.count, 3)
        
        if includeDeletions {
            XCTAssertGreaterThan(eventsCount, 0)
            XCTAssertGreaterThanOrEqual(eventDeletionsCount, 0)
        } else {
            XCTAssertEqual(eventsCount, limit)
        }
    }

    // Note: the part of connection using socket.io (ConnectionWebSocket) is tested in the [example application](https://github.com/pryv/app-swift-example)

}
