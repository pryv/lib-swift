//
//  Service.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 02.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

class Service {
    private let utils = Utils()
    
    private var pryvServiceInfoUrl: String
    private var serviceCustomization: [String: Any]
    
    private var pryvServiceInfo: PryvServiceInfo? = nil
    
    // MARK: - public library
    
    /// Inits a service with the service info url and no custom element
    /// - Parameter pryvServiceInfoUrl: url point to /service/info of a Pryv platform as: `https://access.{domain}/service/info`
    init(pryvServiceInfoUrl: String) {
        self.pryvServiceInfoUrl = pryvServiceInfoUrl
        self.serviceCustomization = [String: Any]()
    }
    
    /// Inits a service with the service info url and custom elements
    /// - Parameters:
    ///   - pryvServiceInfoUrl: url point to /service/info of a Pryv platform as: `https://access.{domain}/service/info`
    ///   - serviceCustomization: a json formatted dictionary corresponding to the customizations of the service
    init(pryvServiceInfoUrl: String, serviceCustomization: [String: Any]) {
        self.pryvServiceInfoUrl = pryvServiceInfoUrl
        self.serviceCustomization = serviceCustomization
    }
    
    /// Returns service info parameters
    /// # Example #
    /// - name of the platform: `let serviceName = service.info().name`
    /// See `PryvServiceInfo` for details on available properties
    /// - Returns: the fetched service info object, customized if needed, or nil if problem is encountered while fetching
    public func info() -> PryvServiceInfo? {
        sendServiceInfoRequest() { data in
            if let data = data {
                self.pryvServiceInfo = data
            }
        }
        
        customizeService()
        
        return pryvServiceInfo
    }
    
    /// Constructs the API endpoint from this service and the username and token
    /// - Parameters:
    ///   - username
    ///   - token (optionnal)
    /// - Returns: API Endpoint from a username and token and the PryvServiceInfo
    public func apiEndpointFor(username: String, token: String? = nil) -> String? {
        let serviceInfo = pryvServiceInfo ?? info()
        guard let apiEndpoint = serviceInfo?.api.replacingOccurrences(of: "{username}", with: username) else { print("problem encountered when building the service info api") ; return nil}
        
        return utils.buildPryvApiEndPoint(endpoint: apiEndpoint, token: token)
    }
    
    /// Issue a "login call on the Service" return a Connection on success
    /// **Warning !**: the token of the connection will be a "Personal" token that expires
    /// See [the API](https://api.pryv.com/reference-full/#login-user)
    /// - Parameters:
    ///   - username
    ///   - password
    ///   - appId
    /// - Returns: the user's connection to the appId or nil if problem is encountered
    public func login(username: String, password: String, appId: String) -> Connection? {
        var connection: Connection? = nil
        let loginPayload = ["username": username, "password": password, "appId": appId]
        guard let apiEndpoint = apiEndpointFor(username: username) else { return nil }
        
        sendLoginRequest(endpoint: apiEndpoint, payload: loginPayload) { data in
             if let token = data, let apiEndpoint = self.apiEndpointFor(username: username, token: token) {
                connection = Connection(apiEndpoint: apiEndpoint)
             }
        }
        
        return connection
    }
    
    /// Sends an auth request to the `access` field of the service info and polls the received url
    /// such that the callback function is called when the state of the connection is changed
    /// - Parameters:
    ///   - authPayload: the auth request json formatted data according to [the API reference](https://api.pryv.com/reference/#auth-request)
    ///   - stateChangedCallback: function that will be called as soon as the state of the authentication changes
    /// - Returns: the `authUrl` field from the response to the service info
    /// 
    ///  # Use case example
    ///    ```
    ///    let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    ///    let authUrl = service.setupAuth(
    ///      authRequestParams: [see [the API reference](https://api.pryv.com/reference/#auth-request) for the elements],
    ///      stateChangedCallback: callback
    ///    )
    ///    // open a web view with the `authUrl` to let the user login
    ///
    ///    func callback(state: AuthState) {
    ///            switch state {
    ///            case .accepted:
    ///                print("ACCEPTED")
    ///            case .need_signin:
    ///            case .refused:
    ///                print("REFUSED")
    ///            }
    ///    }
    ///    ```
    public func setUpAuth(authPayload: [String: Any], stateChangedCallback: (AuthState) -> ()) -> String {
        /** TODO
         
            1. Envoyer une auth request à info().access
            2. Recevoir les champs: `authUrl`, `poll` et `poll_rate_ms`
            3. Retourner le champs `authUrl`
            4. Set un timer à `poll_rate_ms`
            5. À chaque interruption du timer, lancer une GET request à l'url `poll`
            6. Garder une variable `state` pour détecter le changement pour le callback
            7. Si la réponse de la requête change, invalider le timer et appeler le callback sur le nouveau `state`
         */
        return ""
    }
    
    /// This function will be implemented later, according to the documentation on [lib-js](https://github.com/pryv/lib-js#pryvbrowser--visual-assets)
    public func assets() {
        // TODO
    }
    
    // MARK: - private helpers functions for the library
    
    /// Customizes the service info parameters
    private func customizeService() {
        if let register = serviceCustomization["register"] as? String { pryvServiceInfo?.register = register }
        if let access = serviceCustomization["access"] as? String { pryvServiceInfo?.access = access }
        if let api = serviceCustomization["api"] as? String { pryvServiceInfo?.api = api }
        if let name = serviceCustomization["name"] as? String { pryvServiceInfo?.name = name }
        if let home = serviceCustomization["home"] as? String { pryvServiceInfo?.home = home }
        if let support = serviceCustomization["support"] as? String { pryvServiceInfo?.support = support }
        if let terms = serviceCustomization["terms"] as? String { pryvServiceInfo?.terms = terms }
        if let eventTypes = serviceCustomization["eventTypes"] as? String { pryvServiceInfo?.eventTypes = eventTypes }
    }
    
    /// Decodes json data into a PryvServiceInfo object
    /// - Parameter json: json encoded data structured as a service info object
    /// - Returns: the PryvServiceInfo object corresponding to the json or nil if problem is encountered
    private func decodeServiceInfo(from json: Data) -> PryvServiceInfo? {
        let decoder = JSONDecoder()
        
        do {
            let service = try decoder.decode(PryvServiceInfo.self, from: json)
            return service
        } catch {
            print("problem encountered when parsing the service info response: " + error.localizedDescription)
            return nil
        }
    }
    
    /// Fetches the service info from the service info url
    /// - Parameter completion: closure containing the parsed data, if any, from the response of the request to the service info url
    /// - Returns: the closure `completion` is called after the function returns to access the service info
    private func sendServiceInfoRequest(completion: @escaping (PryvServiceInfo?) -> ()) {
        guard let url = URL(string: pryvServiceInfoUrl) else { print("problem encountered: cannot access url \(pryvServiceInfoUrl)") ; return completion(nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [String: Any]())
        
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error, data == nil { print("problem encountered when requesting the service info") ; return completion(nil) }
            let service = self.decodeServiceInfo(from: data!)
            return completion(service)
        }
        
        task.resume()
    }
    
    /// Sends a login request to the register url from the service info and returns the response token
    /// - Parameters:
    ///   - payload: the json formatted payload for the request: username, password and app id
    ///   - completion: closure containing the parsed data, if any, from the response of the request
    ///   - endpoint: the api endpoint given by the service info
    /// - Returns: the closure `completion` is called after the function returns to access the token
    private func sendLoginRequest(endpoint: String, payload: [String: Any], completion: @escaping (String?) -> ()) {
        guard let url = URL(string: endpoint) else { print("problem encountered: cannot access register url \(endpoint)") ; return completion(nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("/auth/login", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let _ = error, data == nil { print("problem encountered when requesting login") ; return completion(nil) }

            guard let loginResponse = data, let jsonResponse = try? JSONSerialization.jsonObject(with: loginResponse), let dictionary = jsonResponse as? [String: Any] else {
                print("problem encountered when parsing the login response")
                return completion(nil)
            }
            
            let token = dictionary["token"] as? String
            return completion(token)
        }

        task.resume()
    }

}
