//
//  Connection.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public class Connection {
    private let utils = Utils()
    
    private var apiEndpoint: String
    private var endpoint: String
    private var token: String?
    
    /// Creates a connection object from the api endpoint
    /// - Parameter apiEndpoint
    init(apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
        (self.endpoint, self.token) = utils.extractTokenAndEndpoint(apiEndpoint: apiEndpoint) ?? ("", nil)
    }
    
    /// Getter for the field `apiEndpoint`
    /// - Returns: the endpoint given in the constructor
    public func getApiEndpoint() -> String {
        return apiEndpoint
    }
}
