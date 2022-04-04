//
//  Interceptorr.swift
//  Networking
//
//  Created by Ivan Stajcer on 04.04.2022..
//

import Foundation

enum RetryResult {
    case retry
    case doNotRetry
}

protocol Interceptor {
    func adapt( urlRequest: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void)
    func retry(_ request: URLRequest, _ reponse: URLResponse?, dueTo error: Error?, completion: @escaping (RetryResult) -> Void)
}
