//
//  WeatherRequest.swift
//  Networking
//
//  Created by Ivan Stajcer on 07.04.2022..
//

import Foundation

struct WeatherRequest: NetworkRequestProtocol {
    var body: [String : Any]?
    var baseUrl: String = "https://api.openweathermap.org/data/2.5/weather"
    var headers: [String : String] = [:]
    var queryParameters: [String : String] = ["lat" : "45.5550", "lon" : "18.6955", "appid" : "33a595b1052037a58ebbd6503b0303ac"]
    var httpMethod: HTTPMetod = .GET
    
    mutating func addQueryParameter(key: String, value: String) {
        queryParameters[key] = value
    }
}
