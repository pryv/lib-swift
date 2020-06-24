//
//  PryvError.swift
//  Alamofire
//
//  Created by Sara Alemanno on 24.06.20.
//

import Foundation

public enum PryvError: Error {
    case responseError(_ message: String) // if we receive an error from the server
    case requestError(_ message: String)
    case decodingError // if we have an error while decoding received data
}
