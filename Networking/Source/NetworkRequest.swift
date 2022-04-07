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

protocol NetworkRequestProtocol {
    var baseUrl: String { get }
    var headers: [String : String] { get }
    var queryParameters: [String : String] { get }
    var httpMethod: HTTPMetod { get }
    var body: [String: Any]? { get set }
}
