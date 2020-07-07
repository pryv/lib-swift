//
//  Readmetests.swift
//  PryvApiSwiftKit_Tests
//
//  Created by Sara Alemanno on 07.07.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//
import XCTest
import Mocker
@testable import Promises
@testable import PryvApiSwiftKit

class ReadmeTests: XCTestCase {
    // TODO: 
    
    func testreadme() {
        let apiEndpoint = "https://ckcbrod5o07441vd3q69hisi3@testuser.pryv.me"
        let connection = Connection(apiEndpoint: apiEndpoint)
        XCTAssertEqual(connection.getApiEndpoint(), apiEndpoint)
        
        let payload: Event = ["streamId": "data", "type": "picture/attached"]
        let filePath = "./test/my_image.png"
        let mimeType = "image/png"
        
        var res: Json?
        connection.createEventWithFile(event: payload, filePath: filePath, mimeType: "application/pdf").then { result in
            res = result
        }.catch { error in
            print(error.localizedDescription)
        }
        
        XCTAssert(waitForPromises(timeout: 20))
        print(String(describing: res))
    }
}
