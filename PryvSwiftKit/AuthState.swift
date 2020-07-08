//
//  AuthState.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

/// Possible states for the authentication response
public enum AuthState {
    case need_signin
    case accepted
    case refused
    case timeout
}

/// State of the authentication response with corresponding endpoint, if `.accepted`
public struct AuthResult {
    public var state: AuthState
    public var apiEndpoint: String?
}
