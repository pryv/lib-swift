//
//  AuthStates.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

enum AuthState {
    case error
    case loading
    case initialized
    case authorized
    case logout
}
