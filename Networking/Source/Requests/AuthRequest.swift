//
//  AuthRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 05.04.2022..
//

import Foundation

struct AuthRequest: NetworkRequestProtocol {
    var baseUrl = API.baseUrlAuth
    var headers: [String : String] = API.baseHeadersAuth
    var queryParameters: [String : String] = [:]
    var httpMethod: HTTPMetod = .POST
    var body: [String : Any]? = [:]
    
    mutating func createBody(username: String, password: String) {
        body = [:]
        body?.updateValue(username, forKey: "username")
        body?.updateValue(password, forKey: "password")
        body?.updateValue(API.Auth.stageGrantType, forKey: "grant_type")
        body?.updateValue(API.Auth.stageClientId, forKey: "client_id")
        body?.updateValue(API.Auth.stageClientSecret, forKey: "client_secret")
        body?.updateValue(API.Auth.stageScope, forKey: "scope")
    }
}
