//
//  NetworkRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import Foundation

enum HTTPMetod: String {
    case GET, POST, PUT, PATCH, DELETE
}

enum ResourceEncoding: String {
    case urlEncoded
    case json
}

protocol NetworkRequestProtocol {
    var path: String { get }
    var headers: [String : String] { get }
    var queryParameters: [String : String] { get }
    var httpMethod: HTTPMetod { get }
    var resourceEncoding: ResourceEncoding { get }
    var body: [String: Any]? { get set }
}
