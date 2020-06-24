//
//  ConnectionWebSocketTests.swift
//  PryvApiSwiftKit_Tests
//
//  Created by Sara Alemanno on 23.06.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import SocketIO
@testable import PryvApiSwiftKit

class ConnectionWebSocketTests: XCTestCase {
    let connection = ConnectionWebSocket(apiEndpoint: "https://ckbrz1pmj009o1vd38iqvavv5@testuser.pryv.me")
    
    func testExample() {
        connection.subscribe(message: .eventsChanged) { data, ack in
            print("Events changed")
            self.connection.emitWithData(methodId: "events.get", params: Json()) { data in
                print("New (updated) events!")
                data.forEach {
                    print(String(describing: $0))
                }
            }
        }
        
        connection.connect()
        sleep(15)
        connection.disconnect()
    }
    
}
