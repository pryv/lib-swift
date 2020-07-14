//
//  TakTlsSessionManager.swift
//  Example
//
//  Created by Sara Alemanno on 14.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import Alamofire
import TAK
import TakTls

class TakTlsSessionManager: Session {

    /// Use this property to get an Alamofire SessionManager which is configured to use TAK TLS implementation.
    static let sharedInstance: TakTlsSessionManager = TakTlsSessionManager()

    init() {
        // Set up T.A.K
        let tak = try! TAK(licenseFileName: "license_key")
        TakUrlProtocolImpl.takTlsSocketFactory = DefaultTakTlsSocketFactory(tak: tak)
        // Use this in case connections to the backend time out
        TakUrlProtocolImpl.allowSetConnectionCloseHeader = true
        // Configure Alamofire to use T.A.K
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = TimeInterval(TakUrlProtocolImpl.timeout / 1000)
        // This is the critical line, which instructs iOS's stack to give preference to T.A.K for resolving HTTPS URLs
        configuration.protocolClasses?.insert(TakUrlProtocolImpl.self, at: 0)
        
        let delegate = SessionDelegate()
        let rootQueue = DispatchQueue(label: "org.alamofire.session.rootQueue")
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.underlyingQueue = rootQueue
        delegateQueue.name = "org.alamofire.session.sessionDelegateQueue"

        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

        super.init(session: session, delegate: delegate, rootQueue: rootQueue)
    }
}
