//
//  Connection.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public class Connection {
    private let utils = Utils()
    
    private var apiEndpoint: String
    private var endpoint: String
    private var token: String?
    
    /// Creates a connection object from the api endpoint
    /// - Parameter apiEndpoint
    init(apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
        (self.endpoint, self.token) = utils.extractTokenAndEndpoint(apiEndpoint: apiEndpoint) ?? ("", nil)
    }
    
    /// Getter for the field `apiEndpoint`
    /// - Returns: the endpoint given in the constructor
    public func getApiEndpoint() -> String {
        return apiEndpoint
    }
    
    /// Issue a [Batch call](https://api.pryv.com/reference/#call-batch)
    /// - Parameter APICalls: array of method calls in json formatted string
    /// - Returns: array of results matching each method call in order
    // TODO: handle result callback
    public func api(APICalls: String) -> [Any] {
        // TODO: implement
        
    }
    
    /// ADD Data Points to HFEvent (flatJSON format) as described in the [reference API](https://api.pryv.com/reference/#add-hf-series-data-points)
    /// - Parameters:
    ///   - eventId
    ///   - fields
    ///   - points
    public func addPointsToHFEvent(eventId: String, fields: [String], points: [[Any]]) {
        // TODO: post to endpoint/events/{id}/series
        // TODO check if error
    }
    
    /// Create an event with attached file
    /// - Parameters:
    ///   - event
    ///   - filePath
    /// - Returns: the created event
    public func createEventWithFile(event: Event, filePath: String) -> Event {
        // TODO: implement
    }
    
}
