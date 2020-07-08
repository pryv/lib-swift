//
//  Data+append.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 09.06.20.
//

import Foundation

/// Extends `Data` to allow to append strings
extension Data {
    
    /// Appends a string to this data
    /// - Parameter string
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
