//
//  PryvError.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 24.06.20.
//

import Foundation

public enum PryvError: Error {
    case responseError(_ message: String)
    case decodingError
    case requestError(_ message: String)
}

extension PryvError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .responseError(let message):
            return NSLocalizedString(message, comment: "response-error")
        case .requestError(let message):
            return NSLocalizedString(message, comment: "request-error")
        case .decodingError:
            return NSLocalizedString("Decoding error", comment: "decoding-error")
        }
    }
}
