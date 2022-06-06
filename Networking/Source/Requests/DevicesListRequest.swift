//
//  DevicesListRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 05.04.2022..
//

import Foundation

struct DevicesListRequest: NetworkRequestProtocol {
    var path = "things"
    var resourceEncoding: ResourceEncoding = .json
    var headers: [String : String] = ConfigurationProvider.shared.baseHeaders
    var queryParameters: [String : String]  = ["pimInfo": "true", "thingState": "true"]
    var httpMethod: HTTPMetod = .GET
    var body: [String : Any]? = nil
}
