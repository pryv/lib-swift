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
    
    private let callBatches = [MethodCall]()
    // TODO: corresponding to the following json
        /* """
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
          },
          {
            "method": "events.create",
            "params": {
              "time": 1385046854.282,
              "streamIds": [
                "diastolic"
              ],
              "type": "pressure/mmhg",
              "content": 80
            }
          }
        ]
        """*/ 
    
    override func setUp() {
        
        connection = Connection(apiEndpoint: apiEndpoint)
        mockResponses()
    }
    
    func testCallBatch() {
        let result = connection?.api(APICalls: callBatches)
        
        // TODO: check result = mockeddata
    }
    
    func testCallBatchCallback() {
        // TODO
    }

    private func mockResponses() {
        let mockCallBatch = Mock(url: URL(string: apiEndpoint)!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        
        Mocker.register(mockCallBatch)
    }
}
