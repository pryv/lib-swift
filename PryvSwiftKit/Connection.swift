//
//  Connection.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import Alamofire
import Promises

public typealias Event = Json
public typealias Parameters = [String: String]
public typealias APICall = Json

public class Connection {
    private let utils = Utils()
    
    private var apiEndpoint: String
    private var endpoint: String
    private var token: String?
    private var service: Service?
    
    // MARK: - public library
    
    /// Creates a connection object from the api endpoint
    /// - Parameters:
    ///   - apiEndpoint
    ///   - service: eventually initialize Connection with a Service
    public init(apiEndpoint: String, service: Service? = nil) {
        self.apiEndpoint = apiEndpoint
        (self.endpoint, self.token) = utils.extractTokenAndEndpoint(from: apiEndpoint) ?? ("", nil)
        self.service = service
    }
    
    /// Getter for Service object relative to this connection
    /// - Returns: the service
    public func getService() -> Service {
        if let _ = service {
            return service!
        }
        self.service = Service(pryvServiceInfoUrl: endpoint + "service/info")
        return service!
    }
    
    /// Getter for the field `apiEndpoint`
    /// - Returns: the api endpoint given in the constructor
    public func getApiEndpoint() -> String {
        return apiEndpoint
    }
    
    /// Getter for the username relative to this connection
    /// - Returns: the promise containing the username
    public func username() -> Promise<String> {
        return getService().info().then { serviceInfo in
            return self.utils.extractUsername(from: self.apiEndpoint)!
        }
    }
    
    /// Issue a [Batch call](https://api.pryv.com/reference/#call-batch)
    /// - Parameters:
    ///   - APICalls: array of method calls in json formatted string
    ///   - handleResults: callbacks indexed by the api calls indexes, i.e. `[0: func]` means "apply function `func` to result of api call 0"
    /// - Returns: promise to array of results matching each method call in order
    public func api(APICalls: [APICall], handleResults: [Int: (Event) -> ()]? = nil) -> Promise<[Json]> {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: APICalls)
        if let _ = token {
            request.addValue(token!, forHTTPHeaderField: "Authorization")
        }
        
        return Promise<[Json]>(on: .global(qos: .background)) { (fullfill, reject) in
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! Json
                    
                    if let error = response["error"] as? Json, let message = error["message"] as? String {
                        reject(PryvError.responseError(message))
                        return
                    }
                    
                    guard let results = response["results"] as? [Json] else {
                        reject(PryvError.decodingError)
                        return
                    }
                    
                    if let error = results.first?["error"] as? Json {
                        reject(PryvError.requestError(error["message"] as! String))
                        return
                    }
                    
                    if let callbacks = handleResults {
                        for (i, callback) in callbacks {
                            if i >= results.count {
                                print("problem encountered when applying the callback \(i): index out of bounds")
                            }
                            callback(results[i])
                        }
                    }
                    fullfill(results)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    /// Add Data Points to HFEvent (flatJSON format) as described in the [reference API](https://api.pryv.com/reference/#add-hf-series-data-points)
    /// - Parameters:
    ///   - eventId
    ///   - fields
    ///   - points
    /// - Returns: a promise containing the response, or an error if a problem occurred
    public func addPointsToHFEvent(eventId: String, fields: [String], points: [[Any]]) -> Promise<Json> {
        let parameters: Json = [
            "format": "flatJSON",
            "fields": fields,
            "points": points
        ]
        
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events/\(eventId)/series" : apiEndpoint + "/events/\(eventId)/series"
        var request = URLRequest(url: URL(string: string)!)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        if let _ = token {
            request.addValue(token!, forHTTPHeaderField: "Authorization")
        }
        
        return Promise<Json>(on: .global(qos: .background)) { (fullfill, reject) in
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! Json
                    if let error = response["error"] as? Json, let message = error["message"] as? String {
                        reject(PryvError.responseError(message))
                        return 
                    }
                    fullfill(response)
                case .failure(let error):
                    reject(PryvError.requestError(error.localizedDescription))
                }
            }
        }
    }

    /// Streamed [get event](https://api.pryv.com/reference/#get-events)
    /// - Parameters:
    ///   - queryParams: see `events.get` parameters
    ///   - forEachEvent: function taking one event as parameter, will be called for each event
    /// - Returns: promise to result.body transformed with `eventsCount: {count}` replacing `events: [...]`
    public func getEventsStreamed(queryParams: Json? = Json(), forEachEvent: @escaping (Event) -> ()) -> Promise<Json> {
        let parameters: Json = [
            "method": "events.get",
            "params": queryParams!
        ]
        
        var request = URLRequest(url: URL(string: self.endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: [parameters])
        if let _ = token {
            request.addValue(token!, forHTTPHeaderField: "Authorization")
        }
        
        return Promise<Json>(on: .global(qos: .background), { (fullfill, reject) in
            var partialChunk: String? = nil
            var eventsCount = 0
            var eventDeletionsCount = 0
            var meta = Json()
            AF.streamRequest(request).responseStream { stream in
                switch stream.event {
                case let .stream(result):
                    switch result {
                    case let .success(data): // Library doc: there cannot be a failure when streaming
                        guard let string = String(data: data, encoding: .utf8) else { return }
                        let parsedResult = self.parseEventsChunked(string: (partialChunk ?? "") + string, forEachEvent: forEachEvent)
                        eventsCount += parsedResult.eventsCount
                        eventDeletionsCount += parsedResult.eventDeletionsCount
                        partialChunk = parsedResult.remaining
                        meta = parsedResult.meta != nil ? parsedResult.meta! : meta
                    }
                case .complete(_):
                    var result: Json = [
                        "meta": meta,
                        "eventsCount": eventsCount,
                    ]
                    if let includeDeletions = queryParams?["includeDeletions"] as? Bool, includeDeletions {
                        result["eventDeletionsCount"] = eventDeletionsCount
                    }
                    fullfill(result)
                }
            }
        })
    }
    
    /// Create an event with attached file
    /// - Parameters:
    ///   - event: description of the new event to create
    ///   - filePath
    ///   - mimeType: the mimeType of the file in `filePath`
    /// - Returns: promise containing the new created event with attachement corresponding to the file in `filePath`
    public func createEventWithFile(event: Event, filePath: String, mimeType: String) -> Promise<Event> {
        let url = NSURL(fileURLWithPath: filePath)
        let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: filePath, data: url.dataRepresentation, mimeType: mimeType)
        
        return createEventWithFormData(event: event, parameters: nil, files: [media])
    }
    
    /// Create an event with attached file encoded as [multipart/form-data content](https://developer.mozilla.org/en-US/docs/Web/API/FormData/FormData)
    /// - Parameters:
    ///   - event: description of the new event to create
    ///   - parameters: the string parameters for the add attachement(s) request (optional)
    ///   - files: the attachement(s) to add (optional)
    /// - Returns: promise containing the new created event with an optionnal attachment
    public func createEventWithFormData(event: Json, parameters: Parameters? = nil, files: [Media]? = nil) -> Promise<Event> {
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events" : apiEndpoint + "/events"
        var request = URLRequest(url: URL(string: string)!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: event)
        if let _ = token {
            request.addValue(token!, forHTTPHeaderField: "Authorization")
        }
        
        let eventId = Promise<String>(on: .global(qos: .background), { (fullfill, reject) in
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! NSDictionary
                    let event = response.object(forKey: "event") as? Event
                    guard let eventId = event?["id"] as? String else {
                        let connError = PryvError.decodingError
                        reject(connError)
                        return
                    }
                    fullfill(eventId)
                case .failure(let error):
                    let connError = PryvError.requestError(error.localizedDescription)
                    reject(connError)
                }
            }
        })
        
        return eventId.then { eventId in
            let boundary = "Boundary-\(UUID().uuidString)"
            let httpBody = self.createData(with: boundary, from: parameters, and: files)
            return self.addFormDataToEvent(eventId: eventId, boundary: boundary, httpBody: httpBody)
        }
    }
    
    /// Adds an attached file to an event with id `eventId`
    /// - Parameters:
    ///   - eventId
    ///   - filePath
    ///   - mimeType: the mimeType of the file in `filePath`
    /// - Returns: promise containing the given event with `eventId` with attachement corresponding to the file in `filePath`
    public func addFileToEvent(eventId: String, filePath: String, mimeType: String) -> Promise<Event> {
        let url = NSURL(fileURLWithPath: filePath)
        let media = Media(key: "file-\(UUID().uuidString)-\(String(describing: token))", filename: filePath, data: url.dataRepresentation, mimeType: mimeType)
        let boundary = "Boundary-\(UUID().uuidString)"
        let httpBody = createData(with: boundary, from: nil, and: [media])
        
        return addFormDataToEvent(eventId: eventId, boundary: boundary, httpBody: httpBody)
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
    
    /// Send a request to add an attachment to an existing event with id `eventId`
    /// - Parameters:
    ///   - eventId
    ///   - boundary: the boundary corresponding to the attachement to add
    ///   - httpBody: the data corresponding to the attachement to add, or on the error
    /// - Returns: a promise containing the event with id `eventId` with an attachement
    public func addFormDataToEvent(eventId: String, boundary: String, httpBody: Data) -> Promise<Event> {
        let string = apiEndpoint.hasSuffix("/") ? apiEndpoint + "events/\(eventId)" : apiEndpoint + "/events/\(eventId)"
        var request = URLRequest(url: URL(string: string)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        if let _ = token {
            request.addValue(token!, forHTTPHeaderField: "Authorization")
        }
        
        return Promise<Event>(on: .global(qos: .background), { (fullfill, reject) in
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! Json
                    guard let event = response["event"] as? Event else {
                        reject(PryvError.decodingError)
                        return
                    }
                    fullfill(event)
                case .failure(let error):
                    reject(PryvError.requestError(error.localizedDescription))
                }
            }
        })
    }
    
    /// Create `Data` from the `parameters` and the `files` encoded as [multipart/form-data content](https://developer.mozilla.org/en-US/docs/Web/API/FormData/FormData)
    /// - Parameters:
    ///   - boundary: the boundary of the multipart/form-data content
    ///   - parameters: the string parameters
    ///   - files: the attachement(s)
    /// - Returns: the data as `Data` corresponding with `boundary`, `parameters` and `files`
    public func createData(with boundary: String, from parameters: Parameters?, and files: [Media]?) -> Data {
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
    
    // MARK: - private helpers functions for the library
    
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
