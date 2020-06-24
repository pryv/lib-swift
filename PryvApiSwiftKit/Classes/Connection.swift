//
//  Connection.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import Alamofire

public typealias Event = Json
public typealias Parameters = [String: String]
public typealias APICall = Json

public class Connection {
    private let utils = Utils()
    
    private var apiEndpoint: String
    private var endpoint: String
    private var token: String?
    
    // MARK: - public library
    
    /// Creates a connection object from the api endpoint
    /// - Parameter apiEndpoint
    public init(apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
        (self.endpoint, self.token) = utils.extractTokenAndEndpoint(from: apiEndpoint) ?? ("", nil)
    }
    
    /// Getter for the field `apiEndpoint`
    /// - Returns: the api endpoint given in the constructor
    public func getApiEndpoint() -> String {
        return apiEndpoint
    }
    
    /// Issue a [Batch call](https://api.pryv.com/reference/#call-batch)
    /// - Parameters:
    ///   - APICalls: array of method calls in json formatted string
    ///   - handleResults: callbacks indexed by the api calls indexes, i.e. `[0: func]` means "apply function `func` to result of api call 0"
    /// - Returns: array of results matching each method call in order 
    public func api(APICalls: [APICall], handleResults: [Int: (Event) -> ()]? = nil, completionHandler: @escaping (_ results: [Json]?, _ error: Error?) -> Void) {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: APICalls)
        
        AF.request(request).responseJSON { response in
            switch response.result {
            case .success(let JSON):
                let response = JSON as! NSDictionary
                
                if let error = response.object(forKey: "error") {
                    completionHandler(nil, PryvError.responseError(String(describing: error)))
                }
                
                if let results = response.object(forKey: "results"), let json = results as? [Json] {
                    if let callbacks = handleResults {
                        for (i, callback) in callbacks {
                            if i >= json.count { print("problem encountered when applying the callback \(i): index out of bounds") }
                            callback(json[i])
                        }
                    }
                    completionHandler(json, nil)
                } else {
                    completionHandler(nil, PryvError.decodingError)
                }

            case .failure(let error):
                completionHandler(nil, PryvError.requestError(error.localizedDescription))
            }
        }
    }
    
    /// Add Data Points to HFEvent (flatJSON format) as described in the [reference API](https://api.pryv.com/reference/#add-hf-series-data-points)
    /// - Parameters:
    ///   - eventId
    ///   - fields
    ///   - points
    public func addPointsToHFEvent(eventId: String, fields: [String], points: [[Any]]) {
        let payload: Json = [
            "format": "flatJSON",
            "fields": fields,
            "points": points
        ]
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events/\(eventId)/series" : apiEndpoint + "/events/\(eventId)/series"
        guard let url = URL(string: string) else { print("problem encountered: cannot access register url \(string)") ; return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let _ = error, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 { print("problem encountered when requesting to add a high frequency event") ; return }
        }
        
        task.resume()
    }

    /// Streamed [get event](https://api.pryv.com/reference/#get-events)
    /// - Parameters:
    ///   - queryParams: see `events.get` parameters
    ///   - forEachEvent: function taking one event as parameter, will be called for each event
    ///   - log: function taking the result of the request as parameter
    /// - Returns: the two escaping callbacks to handle the results: the events and the success/failure of the request 
    public func getEventsStreamed(queryParams: Json? = Json(), forEachEvent: @escaping (Event) -> (), completion: @escaping (Json) -> ()) {
        let parameters: Json = [
            "method": "events.get",
            "params": queryParams!
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(token ?? "", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONSerialization.data(withJSONObject: [parameters])
        
        var partialChunk: String? = nil
        var eventsCount = 0
        var eventDeletionsCount = 0
        var meta = Json()
        AF.streamRequest(request).responseStream { stream in
            switch stream.event {
            case let .stream(result):
                switch result {
                case let .success(data):
                    guard let string = String(data: data, encoding: .utf8) else { return }
                    let parsedResult = self.parseEventsChunked(string: (partialChunk ?? "") + string, forEachEvent: forEachEvent)
                    eventsCount += parsedResult.eventsCount
                    eventDeletionsCount += parsedResult.eventDeletionsCount
                    partialChunk = parsedResult.remaining
                    meta = parsedResult.meta != nil ? parsedResult.meta! : meta
                }
            case .complete(_):
                let result: Json = [
                    "meta": meta,
                    "eventsCount": eventsCount,
                    "eventDeletionsCount": eventDeletionsCount
                ]
                completion(result)
            }
        }
    }
    
    /// Create an event with attached file
    /// - Parameters:
    ///   - event: description of the new event to create
    ///   - filePath
    ///   - mimeType: the mimeType of the file in `filePath`
    /// - Returns: the newly created event with attachement corresponding to the file in `filePath`
    public func createEventWithFile(event: Event, filePath: String, mimeType: String) -> Event? {
        let url = NSURL(fileURLWithPath: filePath)
        let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: filePath, data: url.dataRepresentation, mimeType: mimeType)
        
        return createEventWithFormData(event: event, parameters: nil, files: [media])
    }
    
    /// Create an event with attached file encoded as [multipart/form-data content](https://developer.mozilla.org/en-US/docs/Web/API/FormData/FormData)
    /// - Parameters:
    ///   - event: description of the new event to create
    ///   - parameters: the string parameters for the add attachement(s) request (optional)
    ///   - files: the attachement(s) to add (optional)
    /// - Returns: the newly created event with attachment(s) corresponding to `parameters` and `files`
    /// # Note
    /// If no `parameters`, nor `files` are given, the method will just create a new event.
    public func createEventWithFormData(event: Event, parameters: Parameters? = nil, files: [Media]? = nil) -> Event? {
        var event = sendCreateEventRequest(payload: event)
        guard let eventId = event?["id"] as? String else { print("problem encountered when creating the event") ; return nil }
    
        let boundary = "Boundary-\(UUID().uuidString)"
        let httpBody = createData(with: boundary, from: parameters, and: files)
        if let result = addFormDataToEvent(eventId: eventId, boundary: boundary, httpBody: httpBody) {
            event = result
        }
        
        return event
    }
    
    /// Adds an attached file to an event with id `eventId`
    /// - Parameters:
    ///   - eventId
    ///   - filePath
    ///   - mimeType: the mimeType of the file in `filePath`
    /// - Returns: the newly created event with attachement corresponding to the file in `filePath`
    public func addFileToEvent(eventId: String, filePath: String, mimeType: String) -> Event? {
        let url = NSURL(fileURLWithPath: filePath)
        let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: filePath, data: url.dataRepresentation, mimeType: mimeType)
        let boundary = "Boundary-\(UUID().uuidString)"
        let httpBody = createData(with: boundary, from: nil, and: [media])
        
        if let event = addFormDataToEvent(eventId: eventId, boundary: boundary, httpBody: httpBody) {
            return event
        }
        
        return nil
    }
    
    /// Get an image preview for a given event, if this event contains an image attachment
    /// - Parameter eventId
    /// - Returns: the data containing the preview
    /// # Note
    ///     This function is only applicable for events that contain image. In case the event does not have any image attached, its behavior is undefined.
    public func getImagePreview(eventId: String) -> Data? {
        let previewPath = "\(eventId)?w=256&h=256&auth=\(token ?? "")"
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "previews/events/\(previewPath)" : apiEndpoint + "/previews/events/\(previewPath)"
        guard let url = URL(string: string) else { print("problem encountered: cannot access register url \(string)") ; return nil }
        let nsData = NSData(contentsOf: url)
        return nsData as Data?
    }
    
    // MARK: - private helpers functions for the library
        
    /// Send an `events.create` request
    /// - Parameter payload: description of the new event to create
    /// - Returns: the newly created event
    private func sendCreateEventRequest(payload: Json) -> Event? {
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events" : apiEndpoint + "/events"
        guard let url = URL(string: string) else { print("problem encountered: cannot access register url \(string)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        var result: [String: Any]? = nil
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting event") ; group.leave() ; return }
            
            guard let eventResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: eventResponse), let dictionary = jsonResponse as? Json else { print("problem encountered when parsing the event response") ; group.leave() ; return }
            
            result = dictionary["event"] as? Event
            /*
                Note: this result can only be an event.
                If the result is an error, the returned value will be nil.
                The function that calls this function is responsible for checking that the result is ≠ nil.
            */
            group.leave()
        }
        
        group.enter()
        task.resume()
        group.wait()
        
        return result
    }
    
    /// Send a request to add an attachment to an existing event with id `eventId`
    /// - Parameters:
    ///   - eventId
    ///   - boundary: the boundary corresponding to the attachement to add
    ///   - httpBody: the data corresponding to the attachement to add
    /// - Returns: the event with id `eventId` with an attachement
    private func addFormDataToEvent(eventId: String, boundary: String, httpBody: Data) -> Event? {
        var result: Event? = nil
        
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events/\(eventId)" : apiEndpoint + "/events/\(eventId)"
        guard let url = URL(string: string) else { print("problem encountered: cannot access register url \(string)") ; return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let group = DispatchGroup()
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting event from form data") ; group.leave() ; return }
            
            guard let eventResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: eventResponse), let dictionary = jsonResponse as? Json else { print("problem encountered when parsing the event response") ; group.leave() ; return }
            
            result = dictionary["event"] as? Event
            group.leave()
        }
        
        group.enter()
        task.resume()
        group.wait()
        
        return result
    }
    
    
    /// Create `Data` from the `parameters` and the `files` encoded as [multipart/form-data content](https://developer.mozilla.org/en-US/docs/Web/API/FormData/FormData)
    /// - Parameters:
    ///   - boundary: the boundary of the multipart/form-data content
    ///   - parameters: the string parameters
    ///   - files: the attachement(s)
    /// - Returns: the data as `Data` corresponding with `boundary`, `parameters` and `files`
    private func createData(with boundary: String, from parameters: Parameters?, and files: [Media]?) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        if let files = files {
            for item in files {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(item.key)\"; filename=\"\(item.filename)\"\r\n")
                body.append("Content-Type: \(item.mimeType)\r\n\r\n")
                body.append(item.data)
                body.append("\r\n")
            }
        }
        
        body.append("--\(boundary)--\r\n")
        
        return body
    }
    
    /// Parse a string containing a chunk of the `events.get` response
    /// - Parameters:
    ///   - string: the string corresponding to the chunk of the `events.get` response
    ///   - forEachEvent: function taking one event as parameter, will be called for each event
    /// - Returns: the remaining string, if an event if not entirely received and whether the response was entirely received, i.e. streaming is completed and the number of events received in this chunk
    private func parseEventsChunked(string: String, forEachEvent: @escaping (Event) -> ()) -> (meta: Json?, eventsCount: Int, eventDeletionsCount: Int, remaining: String?) {
        var strCpy = string
        let metaPrefix = "{\"meta\":"
        let eventsPrefix = ",\"results\":[{\"events\":["
        let deletedEventsPrefix = "],\"eventDeletions\":["

        if strCpy.hasPrefix(metaPrefix) {
            strCpy = strCpy.replacingOccurrences(of: metaPrefix, with: "")
        }

        var metaStr = ""
        if strCpy.contains(eventsPrefix) {
            while(!strCpy.hasPrefix(eventsPrefix)) {
                metaStr.append(strCpy.first!)
                strCpy = String(strCpy.dropFirst())
            }
        }

        var eventsStr = strCpy.replacingOccurrences(of: eventsPrefix, with: "") // includes deletions and not deletions
        var eventsStrs = [String]()
        var deletedEventsStrs = [String]()

        var stack = [Character]()
        var remaining: String? = nil

        var event = ""
        while(!eventsStr.hasPrefix(deletedEventsPrefix) && !eventsStr.isEmpty) {
            let character = eventsStr.first!
            eventsStr = String(eventsStr.dropFirst())
            event.append(character)
            if character == "{" {
                stack.append(character)
            }
            if character == "}" {
                let _ = stack.popLast()
            }
            if stack.isEmpty {
                if event != "," {
                    eventsStrs.append(event)
                }
                event = ""
            }
        }
        
        let deletedEventsStr = eventsStr.replacingOccurrences(of: deletedEventsPrefix, with: "")
        for character in deletedEventsStr {
            event.append(character)
            if character == "{" {
                stack.append(character)
            }
            if character == "}" {
                let _ = stack.popLast()
            }
            if stack.isEmpty {
                if event != "," {
                    deletedEventsStrs.append(event)
                }
                event = ""
            }
        }
        
        if !stack.isEmpty {
            remaining = event
        }
        
        let meta = utils.stringToJson(metaStr)
        let events: [Event] = eventsStrs.map({ utils.stringToJson($0) }).filter({ $0 != nil }).map({ $0! })
        let eventsDeleted: [Event] = deletedEventsStrs.map({ utils.stringToJson($0) }).filter({ $0 != nil }).map({ $0! })
        
        events.forEach(forEachEvent)
        eventsDeleted.forEach(forEachEvent)
        
        return (meta: meta, eventsCount: events.count, eventDeletionsCount: eventsDeleted.count, remaining: remaining)
    }
    
}
