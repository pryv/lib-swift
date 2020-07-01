//
//  Service.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 02.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import Promises
import Alamofire

public typealias Json = [String: Any]

/// Data structure holding the service info
public struct PryvServiceInfo: Codable, Equatable {
    public var register: String
    public var access: String
    public var api: String
    public var name: String
    public var home: String
    public var support: String
    public var terms: String
    public var eventTypes: String
}


@available(iOS 10.0, *)
public class Service: Equatable {
    private let utils = Utils()
    private let loginPath = "auth/login"
    private let authPath = "access"
    private let timeout = 90.0 // timeout for auth request in seconds
    
    private var timer: Timer?
    
    private var pryvServiceInfoUrl: String
    private var serviceCustomization: Json?
    
    private var pryvServiceInfo: Promise<PryvServiceInfo>?
    
    private var pollingInfo: (poll: String, poll_ms: Double, callback: (AuthResult) -> ())? {
        didSet {
            var currentState: AuthState? = nil
            var elapsedTime = 0.0
            let poll_s = self.pollingInfo!.poll_ms * 0.001 // Library doc: TimeInteval is in seconds, whereas poll_rate_ms is in milliseconds

            /**
                # Note
                The timer is invalidated if the request is refused or accepted.
                In the case of "NEED_SIGNIN" response, the timer is never invalidated, unless the function `interruptAuth()` is called or in case of a timeout.
            */
            timer = Timer.scheduledTimer(withTimeInterval: poll_s, repeats: true) { _ in
                elapsedTime += poll_s
                if elapsedTime >= self.timeout {
                    currentState = .timeout
                    self.timer?.invalidate()
                    self.pollingInfo!.callback(AuthResult(state: currentState!, endpoint: nil))
                    print("The auth request exceeded timeout and was invalidated.")
                } else {
                    currentState = self.poll(currentState: currentState, poll: self.pollingInfo!.poll, stateChangedCallback: self.pollingInfo!.callback)
                }
            }
        }
    }
    
    // MARK: - public library
    
    /// Inits a service with the service info url and no custom element
    /// - Parameters:
    ///   - pryvServiceInfoUrl: url point to /service/info of a Pryv platform as: [https://access.{domain}/service/info](https://access.{domain}/service/info)
    ///   - serviceCustomization: a json formatted dictionary corresponding to the customizations of the service
    public init(pryvServiceInfoUrl: String, serviceCustomization: Json? = nil) {
        self.pryvServiceInfoUrl = pryvServiceInfoUrl
        self.serviceCustomization = serviceCustomization
    }
    
    /// Returns service info parameters
    /// # Example #
    /// - name of the platform: `let serviceName = service.info().name`
    /// See `PryvServiceInfo` for details on available properties
    /// - Parameter forceFetch: if true, will force fetching service info
    /// - Returns: promise to service info object, customized if needed
    public func info(forceFetch: Bool = false) -> Promise<PryvServiceInfo> {
        if forceFetch || pryvServiceInfo == nil {
            pryvServiceInfo = Promise<PryvServiceInfo>(on: .global(qos: .background), { (fullfill, reject) in
                AF.request(URL(string: self.pryvServiceInfoUrl)!).responseDecodable(of: PryvServiceInfo.self) { response in
                    switch response.result {
                    case .success(var serviceInfo):
                        serviceInfo = self.customize(serviceInfo: serviceInfo, with: self.serviceCustomization)
                        fullfill(serviceInfo)
                    case .failure(let error):
                        let servError = PryvError.requestError(error.localizedDescription)
                        reject(servError)
                    }
                }
            })
        }
        
        return pryvServiceInfo!
    }
    
    /// Return service info parameters
    /// - Returns: the cached content of the service info
    /// # Note
    ///     service.info() needs to be called first, otherwise returns `nil`
    public func infoSync() -> PryvServiceInfo? {
        if pryvServiceInfo == nil {
            return nil
        }
        return try? await(pryvServiceInfo!)
    }
    
    /// Return an API Endpoint from a username and token and a PryvServiceInfo
    /// This is method is rarely used. See `apiEndpointFor` as an alternative.
    /// - Parameters:
    ///   - serviceInfo
    ///   - username
    ///   - token
    /// - Returns: the API endpoint
    public func buildApiEndpoint(serviceInfo: PryvServiceInfo, username: String, token: String? = nil) -> String {
        let endpoint = serviceInfo.api.replacingOccurrences(of: "{username}", with: username)
        return utils.buildPryvApiEndpoint(endpoint: endpoint, token: token)
    }
    
    /// Construct the API endpoint from this service and the username and token
    /// - Parameters:
    ///   - username
    ///   - token (optionnal)
    /// - Returns: API Endpoint from a username and token and the PryvServiceInfo
    public func apiEndpointFor(username: String, token: String? = nil) -> Promise<String> {
        let serviceInfoPromise = pryvServiceInfo ?? info()
        return serviceInfoPromise.then { serviceInfo in
            return self.buildApiEndpoint(serviceInfo: serviceInfo, username: username, token: token)
        }
    }
    
    /// Issue a "login call on the Service" return a Connection on success
    /// **Warning !**: the token of the connection will be a "Personal" token that expires
    /// See [the API](https://api.pryv.com/reference-full/#login-user)
    /// - Parameters:
    ///   - username
    ///   - password
    ///   - appId
    ///   - domain: domain parameter for the `Origin` header, according to the [trusted apps verification](https://api.pryv.com/reference/#trusted-apps-verification/)
    /// - Returns: the user's connection to the appId or nil if problem is encountered
    public func login(username: String, password: String, appId: String, domain: String? = nil) -> Promise<Connection> {
        let loginPayload: Json = ["username": username, "password": password, "appId": appId]
        
        return apiEndpointFor(username: username).then { apiEndpoint in
            let endpoint = apiEndpoint.hasSuffix("/") ? apiEndpoint + self.loginPath : apiEndpoint + "/" + self.loginPath
            var origin: String? = nil
            if let _ = domain {
                origin = "https://login.\(domain!)"
            }
            
            return self.sendLoginRequest(endpoint: endpoint, payload: loginPayload, origin: origin).then { token in
                self.apiEndpointFor(username: username, token: token).then { apiEndpoint in
                   return Connection(apiEndpoint: apiEndpoint)
                }
            }
        }
    }
    
    /// Sends an auth request to the `access` field of the service info and polls the received url
    /// such that the callback function is called when the state of the connection is changed
    /// - Parameters:
    ///   - authSettings: the auth request json formatted according to [the API reference](https://api.pryv.com/reference/#auth-request)
    ///   - stateChangedCallback: function that will be called as soon as the state of the authentication changes
    /// - Returns: a promise containing the `authUrl` field from the response to the service info
    ///
    ///  # Use case example
    ///    ```
    ///    let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    ///    let authUrl = service.setUpAuth(
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
    public func setUpAuth(authSettings: Json, stateChangedCallback: @escaping (AuthResult) -> ()) -> Promise<String> {
        let serviceInfoPromise = pryvServiceInfo ?? info()
        return serviceInfoPromise.then { serviceInfo in
            let endpoint = serviceInfo.register.hasSuffix("/") ? serviceInfo.register + self.authPath : serviceInfo.register + "/" + self.authPath
            
            return Promise<String>(on: .global(qos: .background), { (fullfill, reject) in
                var request = URLRequest(url: URL(string: endpoint)!)
                request.httpMethod = "POST"
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: authSettings)
                
                AF.request(request).responseJSON { response in
                    switch response.result {
                    case .success(let JSON):
                        let response = JSON as! NSDictionary
                        
                        let authURL = response.object(forKey: "authUrl") as? String
                        let poll = response.object(forKey: "poll") as? String
                        let poll_rate_ms = response.object(forKey: "poll_rate_ms") as? Double
                        
                        if let authURL = authURL, let poll = poll, let poll_rate_ms = poll_rate_ms {
                            self.pollingInfo = (poll: poll, poll_ms: poll_rate_ms, callback: stateChangedCallback)
                            fullfill(authURL)
                        } else {
                            let servError = PryvError.decodingError
                            reject(servError)
                        }
                    case .failure(let error):
                        let servError = PryvError.requestError(error.localizedDescription)
                        reject(servError)
                    }
                }
            })
        }
    }
    
    /// Interrupts the timer and stops the polling for the authentication request
    public func interruptAuth() {
        timer?.invalidate()
    }
    
    /// Compares two services based uniquely on their service info url
    /// - Parameters:
    ///   - lhs
    ///   - rhs
    /// - Returns: true if url is the same, false otherwise
    public static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.pryvServiceInfoUrl == rhs.pryvServiceInfoUrl
    }
    
    // MARK: - private helpers functions for the library
    
    /// Customizes the service info parameters
    /// - Parameter json: the json describing the modifications to apply
    /// - Parameter serviceInfo: the service info to customize
    /// - Returns: the modified service info with the values of the given json
    private func customize(serviceInfo: PryvServiceInfo, with json: Json?) -> PryvServiceInfo {
        guard let modifications = json else { return serviceInfo }
        var result = serviceInfo
        
        if let register = modifications["register"] as? String { result.register = register }
        if let access = modifications["access"] as? String { result.access = access }
        if let api = modifications["api"] as? String { result.api = api }
        if let name = modifications["name"] as? String { result.name = name }
        if let home = modifications["home"] as? String { result.home = home }
        if let support = modifications["support"] as? String { result.support = support }
        if let terms = modifications["terms"] as? String { result.terms = terms }
        if let eventTypes = modifications["eventTypes"] as? String { result.eventTypes = eventTypes }
        
        return result
    }
    
    /// Sends a login request to the login url from the service info and returns the response token
    /// - Parameters:
    ///   - endpoint: the api endpoint given by the service info
    ///   - payload: the json formatted payload for the request: username, password and app id
    ///   - origin: the field of the form `https://login.{domain}` to add to the `Origin` header
    /// - Returns: promise containg the token received from the request
    private func sendLoginRequest(endpoint: String, payload: Json, origin: String? = nil) -> Promise<String> {
        return Promise<String>(on: .global(qos: .background), { (fullfill, reject) in
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            if let _ = origin {
                request.addValue(origin!, forHTTPHeaderField: "Origin")
            }
            
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! NSDictionary
                    
                    if let problem = response.object(forKey: "error") as? Json {
                        if let message = problem["message"] as? String {
                            let servError = PryvError.responseError(message)
                            reject(servError)
                            return
                        }
                    }
                    
                    guard let token = response.object(forKey: "token") as? String else {
                        let servError = PryvError.decodingError
                        reject(servError)
                        return
                    }
                    
                    fullfill(token)
                case .failure(let error):
                    let servError = PryvError.requestError(error.localizedDescription)
                    reject(servError)
                }
            }
        })
    }
    
    /// Sends a polling request to the `poll` field from the auth request and returns the status and, if any, the api endpoint
    /// - Parameters:
    ///   - request: the poll url
    ///   - completion: closure containing the parsed data, if any, from the response of the request
    /// - Returns: the closure `completion` is called after the function returns to access the fields `status` and `apiEndpoint`
    private func sendPollingRequest(poll: String, completion: @escaping ((String, String?)?) -> ()) {
        AF.request(poll, method: .get).responseJSON { response in
            switch response.result {
            case .success(let JSON):
                let response = JSON as! NSDictionary
                guard let status = response.object(forKey: "status") as? String else { return completion(nil) }
                let pryvApiEndpoint = response.object(forKey: "apiEndpoint") as? String
                completion((status, pryvApiEndpoint))
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    /// Sends a request to the polling url and calls the callback function from the setUpAuth function if the state changes
    /// - Parameters:
    ///   - currentState: the current state of the response
    ///   - poll: the url for the polling request
    ///   - stateChangedCallback: callback function to call upon a state change
    /// - Returns: the new authentication state according to the polling response
    private func poll(currentState: AuthState?, poll: String, stateChangedCallback: @escaping (AuthResult) -> ()) -> AuthState? {
        var newState = currentState
        
        DispatchQueue.global(qos: .background).async {
            self.sendPollingRequest(poll: poll) { tuple in
                 if let (status, pryvApiEndpoint) = tuple {
                    switch status {
                        
                    case "REFUSED":
                        self.timer?.invalidate()
                        
                        if newState != .refused {
                            newState = .refused
                            let result = AuthResult(state: newState!, endpoint: nil)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    case "NEED_SIGNIN":
                        if newState != .need_signin {
                            newState = .need_signin
                            let result = AuthResult(state: newState!, endpoint: nil)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    case "ACCEPTED":
                        self.timer?.invalidate()
                        guard let pryvApiEndpoint = pryvApiEndpoint else { print("Cannot get field \"apiEndpoint\" from response") ; return }
                        
                        if newState != .accepted {
                            newState = .accepted
                            let result = AuthResult(state: newState!, endpoint: pryvApiEndpoint)
                            DispatchQueue.main.async {
                                stateChangedCallback(result)
                            }
                        }
                        
                    default:
                        print("problem encountered when polling: unexpected status")
                    }
                 }
            }
        }
        
        return newState
    }

}
