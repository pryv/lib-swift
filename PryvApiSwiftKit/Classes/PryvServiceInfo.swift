//
//  PryvServiceInfo.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 02.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

/// Data structure holding the service info
struct PryvServiceInfo: Codable {
    var register: String
    var access: String
    var api: String
    var name: String
    var home: String
    var support: String
    var terms: String
    var eventTypes: String
}
