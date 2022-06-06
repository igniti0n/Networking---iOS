//
//  NetworkResponse.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import Foundation

struct NetworkResponse {
    var data: Data?
    var jsonResponse: Any?
    var error: Error?
    var statusCode: Int?
    var failure: NetworkFailure?
}
