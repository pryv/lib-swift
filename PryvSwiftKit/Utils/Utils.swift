//
//  Utils.swift
//  PryvSwiftKit
//
//  Created by Sara Alemanno on 03.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public class Utils {
    private let regexAPIandToken = "(?i)https?:\\/\\/(.+)@(.+)"
    private let regexSchemaAndPath = "(?i)https?:\\/\\/(.+)"
    private let regexTokenUsername = "(?i)https?:\\/\\/(.+)@(.+)\\.(.+)\\.(.+)"
    private let regexUsername = "(?i)https?:\\/\\/(.+)\\.(.+)\\.(.+)"
    private let regexSocketIO = "(?i)https?:\\/\\/([^\\/]+)\\/(.+)\\?(.+)=(.+)"
    
    public init() { }

    /// Returns the token and the endpoint from an API endpoint
    /// - Parameter apiEndpoint
    /// - Returns: a tuple containing the endpoint and the token (optionnal)
    public func extractTokenAndEndpoint(from apiEndpoint: String) -> (endpoint: String, token: String?)? {
        var apiEp = apiEndpoint
        if !apiEp.hasSuffix("/") {
            apiEp += "/" // add a trailing '/' to end point if missing
        }
        
        let res = regexExec(pattern: regexAPIandToken, string: apiEp)
        if !res.isEmpty { // has token
            return (endpoint: "https://" + res[1], token: res[0])
        }
        
        let res2 = regexExec(pattern: regexSchemaAndPath, string: apiEp)
        if res2.isEmpty {
            print("Problem occurred when extracting the endpoint: cannot find endpoint, invalid URL format")
            return nil
        }

        return (endpoint: "https://" + res2[0], token: nil)
    }
    
    /// Returns the username from an API endpoint
    /// - Parameter apiEndpoint
    /// - Returns: the username
    public func extractUsername(from apiEndpoint: String) -> String? {
        var apiEp = apiEndpoint
        if !apiEp.hasSuffix("/") {
            apiEp += "/" // add a trailing '/' to end point if missing
        }
        
        let res = regexExec(pattern: regexTokenUsername, string: apiEp)
        if !res.isEmpty { // has token
            return res[1]
        }
        
        let res2 = regexExec(pattern: regexUsername, string: apiEp)
        if res2.isEmpty {
            print("Problem occurred when extracting the username: invalid URL format")
            return nil
        }
        
        return res2[0]
    }
    
    /// Parses the socket io URL and extracts the endpoint, the connection parameters, such as token, and the namespace
    /// - Parameter url
    /// - Returns: the endpoint, the connection parameters and the namespace
    public func parseSocketIOURL(url: String) -> (endpoint: String, connectionParams: [String: String], namespace: String) {
        let res = regexExec(pattern: regexSocketIO, string: url)
        
        if res.isEmpty || res.count < 3 {
            print("Problem occurred when extracting the socket io parameters: invalid URL format")
            return ("", [String: String](), "")
        }
        
        var connectionParams = [String: String]()
        for i in stride(from: 2, to: res.count, by: 2) {
            connectionParams[res[i]] = res[i + 1]
        }
        
        return (endpoint: "https://\(res[0])/", connectionParams: connectionParams, namespace: "/\(res[1])")
    }
    
    /// Constructs the API endpoint from the endpoint and the token
    /// - Parameters:
    ///   - endpoint
    ///   - token (optionnal)
    /// - Returns: API Endpoint
    public func buildPryvApiEndpoint(endpoint: String, token: String?) -> String {
        var ep = endpoint
        if !ep.hasSuffix("/") { 
          ep += "/" // add a trailing '/' to end point if missing
        }
        
        if let token = token {
            let res = regexExec(pattern: regexSchemaAndPath, string: ep)
            return "https://" + token + "@" + res[0]
        }
        
        return ep
    }
    
    /// Converts a string to a json dictionnary
    /// - Parameter string
    /// - Returns: the json formatted dictionnary corresponding to the string
    public func stringToJson(_ string: String) -> Json? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        guard let dictionary = json as? Event else { return nil }
        return dictionary
    }
    
    /// Reproduces the behavior of regex.exec() in javascript to split the string according to a given pattern
    /// - Parameters:
    ///   - pattern
    ///   - string
    /// - Returns: an array of the ordered elements in string that match with the pattern
    private func regexExec(pattern: String, string: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsString = string as NSString
        
        guard let matches = regex.firstMatch(in: string, range: NSMakeRange(0, nsString.length)) else { return [] }
        var result = [String]()
        
        for i in 1..<matches.numberOfRanges {
            result.append(nsString.substring(with: matches.range(at: i)))
        }
        
        return result
    }
    
}
