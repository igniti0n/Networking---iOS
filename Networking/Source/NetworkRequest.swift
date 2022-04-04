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
}

struct WeatherNetworkRequest: NetworkRequestProtocol {
    var baseUrl: String = "https://api.openweathermap.org/data/2.5/weather"
    var headers: [String : String] = [:]
    var queryParameters: [String : String] = ["lat" : "45.5550", "lon" : "18.6955", "appid" : "33a595b1052037a58ebbd6503b0303ac"]
    var httpMethod: HTTPMetod = .GET
    
    mutating func addQueryParameter(key: String, value: String) {
        queryParameters[key] = value
    }
}
