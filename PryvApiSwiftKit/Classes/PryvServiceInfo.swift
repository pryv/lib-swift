//
//  PryvServiceInfo.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 02.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

/// Data structure holding the service info
public struct PryvServiceInfo: Codable {
    public var register: String
    public var access: String
    public var api: String
    public var name: String
    public var home: String
    public var support: String
    public var terms: String
    public var eventTypes: String
}
