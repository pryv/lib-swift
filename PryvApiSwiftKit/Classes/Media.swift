//
//  Media.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 09.06.20.
//

import Foundation

// TODO: Rename + doc
public struct Media {
    
    public init(key: String, filename: String, data: Data, mimeType: String) {
        self.key = key
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }
    
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
}
