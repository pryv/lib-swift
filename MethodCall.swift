//
//  MethodCall.swift
//  Mocker
//
//  Created by Sara Alemanno on 08.06.20.
//

import Foundation

public struct MethodCall {
    var method: String
    var params: MethodParams
    var handleResult: ((Any) -> ())?
    
    public init(method: String, params: MethodParams, handleResult: ((Any) -> ())? = nil) {
        self.method = method
        self.params = params
        self.handleResult = handleResult
    }
}

public struct MethodParams {
    
    public init(fromTime: Double? = nil, toTime: Double? = nil, streams: [String]? = nil, tags: [String]? = nil, types: [String]? = nil, running: Bool? = nil, sortAscending: Bool = false, skip: Int? = nil, limit: Int? = nil, state: EventState? = nil, modifiedSince: Double? = nil, includeDeletions: Bool = false) {
        self.fromTime = fromTime
        self.toTime = toTime
        self.streams = streams
        self.tags = tags
        self.types = types
        self.running = running
        self.sortAscending = sortAscending
        self.skip = skip
        self.limit = limit
        self.state = state
        self.modifiedSince = modifiedSince
        self.includeDeletions = includeDeletions
    }
    
    var fromTime: Double? = nil
    var toTime: Double? = nil
    var streams: [String]? = nil
    var tags: [String]? = nil
    var types: [String]? = nil
    var running: Bool? = nil
    var sortAscending: Bool = false
    var skip: Int? = nil
    var limit: Int? = nil
    var state: EventState? = nil
    var modifiedSince: Double? = nil
    var includeDeletions: Bool = false
}

public enum EventState {
    case def
    case trashed
    case all
}
