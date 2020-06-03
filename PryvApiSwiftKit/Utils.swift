//
//  Utils.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

class Utils {
    
    init() {
        
    }
    
//    public func extractTokenAndEndpoint(apiEndpoint: String) -> (String, String?) {
//        // TODO
//    }
    
    /// Constructs the API endpoint from the endpoint and the token
    /// - Parameters:
    ///   - endpoint
    ///   - token (optionnal)
    /// - Returns: API Endpoint
    public func buildPryvApiEndPoint(endpoint: String, token: String?) -> String? {
        var ep = endpoint
        
        if let token = token {
            if endpoint.hasPrefix("https://") {
                ep = String(endpoint.dropFirst(8))
            }
            
            return "https://" + token + "@" + ep
        }
        
        return endpoint
    }
}
