//
//  AuthState.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

/// Possible states for the authentication response
enum AuthState {
    case need_signin
    case accepted
    case refused
    case timeout
}

/// State of the authentication response with corresponding endpoint, if `.accepted`
struct AuthResult {
    var state: AuthState
    var endpoint: String?
}
