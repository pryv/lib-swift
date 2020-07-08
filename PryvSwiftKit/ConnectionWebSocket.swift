//
//  ConnectionWebSocket.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 23.06.20.
//

import Foundation
import SocketIO

public enum Message: String {
    case eventsChanged
    case streamsChanged
    case accessesChanged
}

/// This class proposes the almost same functions as `Connection`, but with real time updates and notifications with [socket.io](https://api.pryv.com/reference/#call-with-websockets)
public class ConnectionWebSocket {
    private let utils = Utils()
    private let manager: SocketManager!
    private var socket: SocketIOClient!
    
    /// Initialize the socket io connection with a URL
    /// - Parameters:
    ///   - url: see [connecting](https://api.pryv.com/reference/#connecting) for the format
    ///   - log: whether to show the socket io connection logs (false, by default)
    public init(url: String, log: Bool = false) {
        let (endpoint, connectParams, namespace) = utils.parseSocketIOURL(url: url)
        
        // Connecting to the socket
        manager = SocketManager(socketURL: URL(string: endpoint)!, config: [.log(log), .connectParams(connectParams)])
        socket = manager.socket(forNamespace: namespace)
    }
    
    /// Emit API calls
    /// See [API reference](https://api.pryv.com/reference/#call-methods) for more information
    /// - Parameters:
    ///   - methodId
    ///   - params: object parameters
    ///   - completion: callback handling received data
    public func emit(methodId: String, params: Json, callback: @escaping ([Any]) -> ()) {
        socket.emitWithAck(methodId, params).timingOut(after: 0) { data in
            callback(data)
        }
    }
    
    /// Connect to the server
    /// # Note
    ///     Only call after adding subscribing to messages
    public func connect() {
        socket.connect()
    }
    
    /// [Subscribe to changes](https://api.pryv.com/reference/#subscribe-to-changes) and apply callback on change
    /// - Parameters:
    ///   - message
    ///   - callback
    public func subscribe(message: Message, callback: @escaping NormalCallback) {
        socket.on(message.rawValue, callback: callback)
    }
    
    /// Disconnect the socket
    /// Use this function when the user logs out
    public func disconnect() {
        socket.removeAllHandlers()
        socket.disconnect()
    }
}
