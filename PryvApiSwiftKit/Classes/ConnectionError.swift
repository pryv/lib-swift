//
//  ConnectionError.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 24.06.20.
//

import Foundation

public enum ConnectionError: Error {
    case responseError(_ message: String)
    case decodingError
    case requestError(_ message: String)
}
