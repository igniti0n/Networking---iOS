//
//  AuthRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 05.04.2022..
//

import Foundation

//    var baseUrl = API.baseUrlAuth

struct AuthRequest: NetworkRequestProtocol {
    var path = "connect/token"
    var resourceEncoding: ResourceEncoding = .urlEncoded
    var headers: [String : String] = API.baseHeadersAuth
    var queryParameters: [String : String] = [:]
    var httpMethod: HTTPMetod = .POST
    var body: [String : Any]? = [:]
    
    mutating func createBody(username: String, password: String) {
        body?.updateValue(username, forKey: "username")
        body?.updateValue(password, forKey: "password")
        body?.updateValue(API.Auth.stageGrantType, forKey: "grant_type")
        body?.updateValue(API.Auth.stageClientId, forKey: "client_id")
        body?.updateValue(API.Auth.stageClientSecret, forKey: "client_secret")
        body?.updateValue(API.Auth.stageScope, forKey: "scope")
    }
}
