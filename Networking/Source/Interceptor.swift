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
    func adapt( urlRequest: URLRequest, networkRequest: NetworkRequestProtocol, completion: @escaping (Result<URLRequest, NetworkFailure>) -> Void)
    func retry(networkRequest: NetworkRequestProtocol, response: NetworkResponse, completion: @escaping (RetryResult) -> Void)
}

extension Interceptor {
    func adapt(urlRequest: URLRequest, networkRequest: NetworkRequestProtocol, completion: @escaping (Result<URLRequest, NetworkFailure>) -> Void) {
        completion(.success(urlRequest))
    }
    
    func retry(networkRequest: NetworkRequestProtocol, response: NetworkResponse, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}


class CustomInterceptor: Interceptor {
    func getTokenFromUserDefaults() -> String? {
        let defaults = UserDefaults.standard
        return defaults.value(forKey: "token") as? String
    }
    
    func adapt(urlRequest: URLRequest, networkRequest: NetworkRequestProtocol, completion: @escaping (Result<URLRequest, NetworkFailure>) -> Void) {
        var newUrlRequest = urlRequest
        if let token = getTokenFromUserDefaults(), !token.isEmpty {
            //newUrlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(newUrlRequest))
    }
    
    func retry(networkRequest: NetworkRequestProtocol, response: NetworkResponse, completion: @escaping (RetryResult) -> Void) {
        completion(.retry)
    }
}
