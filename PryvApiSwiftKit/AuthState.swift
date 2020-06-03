//
//  AuthState.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

/// Three possible states for the authentication response 
enum AuthState {
    case in_progress
    case accepted
    case refused
}
