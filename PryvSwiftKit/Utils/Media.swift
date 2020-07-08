//
//  Media.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 09.06.20.
//

import Foundation

/// Data structure to hold a file
public struct Media {
    
    /// Create a `Media`
    /// - Parameters:
    ///   - key: the key value for the file in the database, must be unique
    ///   - filename
    ///   - data: the data contained in the file
    ///   - mimeType: the type of file: image, text, ...
    public init(key: String, filename: String, data: Data, mimeType: String) {
        self.key = key
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }
    
    let key: String
    let filename: String
    public let data: Data
    let mimeType: String
    
}
