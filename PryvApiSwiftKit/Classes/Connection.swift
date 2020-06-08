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
    public func api(APICalls: String, handleResults: [Int: (([String: Any]) -> ())]? = nil) -> [[String: Any]]? {
        guard let url = URL(string: apiEndpoint) else { print("problem encountered: cannot access register url \(apiEndpoint)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(APICalls.utf8)

        var events: [[String: Any]]? = nil // array of json objects corresponding to events
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting login") ; group.leave() ; return }

            guard let callBatchResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: callBatchResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when parsing the call batch response") ; group.leave() ; return }
            
            let results = dictionary["results"] as? [[String: [String: Any]]]
            events = results?.map { result in
                result["event"] ?? [String: Any]()
            }
            
            group.leave()
        }

        group.enter()
        task.resume()
        group.wait()
        
        guard let callbacks = handleResults, let result = events else { return events }
        
        for (i, callback) in callbacks {
            if i >= result.count { print("problem encountered when applying the callback \(i): index out of bounds") ; return result }
            callback(result[i])
        }
        
        return result
    }
    
    /// ADD Data Points to HFEvent (flatJSON format) as described in the [reference API](https://api.pryv.com/reference/#add-hf-series-data-points)
    /// - Parameters:
    ///   - eventId
    ///   - fields
    ///   - points
    public func addPointsToHFEvent(eventId: String, fields: [String], points: [[Any]]) {
        let payload: [String: Any] = [
            "format": "flatJSON",
            "fields": fields,
            "points": points
        ]
        guard let url = URL(string: endpoint + "events/\(eventId)/series") else { print("problem encountered: cannot access register url \(endpoint)") ; return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let _ = error, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 { print("problem encountered when requesting to add a high frequency event") ; return }
        }
        
        task.resume()
    }
    
    /// Create an event with attached file
    /// - Parameters:
    ///   - event
    ///   - filePath
    /// - Returns: the created event
    // TODO: add file
    public func createEventWithFile(event: [String: Any], filePath: String) -> [String: Any]? {
        guard let url = URL(string: apiEndpoint + "/events") else { print("problem encountered: cannot access register url \(apiEndpoint)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: event)

        var event: [String: Any]? = nil
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting event") ; group.leave() ; return }

            guard let eventResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: eventResponse), let dictionary = jsonResponse as? [String: Any] else { print("problem encountered when parsing the event response") ; group.leave() ; return }
            
            event = dictionary["event"] as? [String: Any]
            group.leave()
        }

        group.enter()
        task.resume()
        group.wait()
        
        return event
    }
    
}
