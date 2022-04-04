//
//  NetworkResponse.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import Foundation

struct NetworkResponse {
    var data: Data?
    var jsonResponse: [String : Any]?
    var failure: NetworkFailure?
}