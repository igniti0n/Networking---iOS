//
//  DevicesListRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 05.04.2022..
//

import Foundation

struct DevicesListRequest: NetworkRequestProtocol {
    var baseUrl = API.baseUrlStage
    var headers: [String : String] = API.baseHeadersStage
    var queryParameters: [String : String] = [:]
    var httpMethod: HTTPMetod = .GET
    var body: [String : Any]? = nil
}
