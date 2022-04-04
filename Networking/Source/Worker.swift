//
//  Worker.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import Foundation

typealias JSONResponse = ([String : Any]?) -> Void
typealias ErrorResponse = (NetworkFailure) -> Void

enum NetworkFailure: Error {
    case statusCode
    case responseInvalid
    case urlRequestConstruction
    case decoding
    case jsonObject
    case error
}

final class Worker {
    // MARK: - Properties
    var interceptor: Interceptor?
    private var jsonResponse: JSONResponse?
    private var failure: ErrorResponse?
    private var decodingClosure: ((Data) -> Void)?
    private var networkResponse: NetworkResponse?
    private var repeatCount = 1
}

// MARK: - Public methods
extension Worker {
    func handleError(response: @escaping ErrorResponse) -> Self {
        failure = response
        return self
    }
    
    func responseJson(response: @escaping JSONResponse) {
        jsonResponse = response
    }
    
    func responseDecodable<T: Decodable>(of type: T.Type, response: @escaping (T?) -> Void) {
        decodingClosure = { [weak self] data in
            guard let decodedObject =  try? JSONDecoder().decode(type, from: data) else {
                response(nil)
                return
            }
            response(decodedObject)
        }
    }
    
    func execute(_ request: NetworkRequestProtocol) -> Self {
        guard let urlRequest = makeURLRequest(request) else {
            failure?(.urlRequestConstruction)
            return self
        }
        
        interceptor?.adapt(urlRequest: urlRequest, completion: { [weak self] result in
            switch result {
            case .success(let request):
                self?.makeNetworkRequest(with: request)
            case .failure(let error):
                print("Error while adapting request: ", error)
                self?.failure?(.urlRequestConstruction)
            }
        })
        return self
    }

    func executeConcurrently(_ request: NetworkRequestProtocol) async -> NetworkResponse {
        let response: NetworkResponse =  await withCheckedContinuation { continuation in
            var networkResponse = NetworkResponse()
            guard let urlRequest = makeURLRequest(request) else {
                networkResponse.failure = .urlRequestConstruction
                continuation.resume(returning: networkResponse)
                return
            }
            interceptor?.adapt(urlRequest: urlRequest, completion: { [weak self] result in
                switch result {
                case .success(let request):
                    self?.makeConcurrentNetworkRequest(with: request, networkResponse: networkResponse, continuation: continuation)
                case .failure(let error):
                    print("Error while adapting request: ", error)
                    networkResponse.failure = .urlRequestConstruction
                    continuation.resume(returning: networkResponse)
                }
            })
        }
        return response
    }
    
    func executeConcurrently<T : Decodable>(_ request: NetworkRequestProtocol, decodeWith type: T.Type) async -> (response: NetworkResponse, model: T?) {
        
        let networkResponse: (response: NetworkResponse, model: T?) = await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: (NetworkResponse(), nil))
                return
            }
            Task {
                let response = await self.executeConcurrently(request)
                guard
                    let data = response.data,
                    let model = try? JSONDecoder().decode(type, from: data) else {
                    continuation.resume(returning: (response, nil))
                    return
                }
                continuation.resume(returning: (response, model))
            }
        }
        return networkResponse
    }
}

// MARK: - Private methods -

private extension Worker {
    func makeURLRequest(_ request: NetworkRequestProtocol) -> URLRequest? {
        guard var components = URLComponents(string: request.baseUrl) else { return nil }
        components.queryItems = request.queryParameters.map({ query in
            URLQueryItem(name: query.key, value: query.value)
        })
    
        guard let url = components.url else { return nil }
        print("Url: ", url)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue
        request.headers.forEach { header in
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        return urlRequest
    }
    
    func makeNetworkRequest(with urlRequest: URLRequest) {
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            // Validate response
            guard let data = self?.validate(data: data, response: response, error: error, errorHandler: { [weak self] networkFailure in
                self?.handleError(error, networkFailure: networkFailure, urlRequest, response)
            }) else {
                return
            }
            // Generate JSON object
            guard
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String : Any]
            else {
                self?.failure?(.jsonObject)
                self?.jsonResponse?(nil)
                return
            }
            // All good, return json object and decode to model if possible
            self?.jsonResponse?(jsonObject)
            self?.decodingClosure?(data)
        }
        task.resume()
    }
    
    func makeConcurrentNetworkRequest(with urlRequest: URLRequest, networkResponse: NetworkResponse, continuation: CheckedContinuation<NetworkResponse, Never>) {
        var networkResponse = NetworkResponse()
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            // Validate response
            guard
                let data = self?.validate(data: data, response: response, error: error, errorHandler: { [weak self] networkFailure in
                    networkResponse.failure = networkFailure
                    self?.handleErrorConcurrently(networkResponse: networkResponse, error, urlRequest, response, continuation: continuation)
                }) else {
                    return
                }
            // Generate JSON object
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String : Any]
            else {
                networkResponse.failure = .jsonObject
               continuation.resume(returning: networkResponse)
                return
            }
            // All good, return json object
            networkResponse.jsonResponse = jsonObject
            continuation.resume(returning: networkResponse)
        }
        task.resume()
    }
    
    func validate(data: Data?, response: URLResponse?, error: Error?,  errorHandler: ErrorResponse?) -> Data? {
        guard
            let data = data,
            let response = response as? HTTPURLResponse else {
                errorHandler?(.responseInvalid)
                return nil
            }
        
        guard (200...299).contains(response.statusCode) else {
            errorHandler?(.statusCode)
            return nil
        }
        
        if let _ = error {
            errorHandler?(.error)
            return nil
        }
        return data
    }
    
    func handleError(_ error: Error?, networkFailure: NetworkFailure, _ request: URLRequest, _ reponse: URLResponse?) {
        guard let interceptor = interceptor else {
            failure?(networkFailure)
            return
        }
        if(repeatCount < 1) {
            print("Will not repeat anymore, returning error: ", error)
            repeatCount = 1
            failure?(networkFailure)
        } else {
            repeatCount -= 1
            interceptor.retry(request, reponse, dueTo: error) { [weak self] retryResult in
                switch retryResult {
                case .retry:
                    print("Repeating request that ended in error:", error)
                    self?.makeNetworkRequest(with: request)
                case .doNotRetry:
                    print("Choosing not to repeat the request.")
                }
            }
        }
    }
    
    func handleErrorConcurrently(networkResponse: NetworkResponse, _ error: Error?, _ request: URLRequest, _ reponse: URLResponse?, continuation: CheckedContinuation<NetworkResponse, Never>) {
        guard let interceptor = interceptor else {
            continuation.resume(returning: networkResponse)
            return
        }
        if(repeatCount < 1) {
            print("Will not repeat anymore, returning error: ", error)
            repeatCount = 1
            continuation.resume(returning: networkResponse)
        } else {
            repeatCount -= 1
            interceptor.retry(request, reponse, dueTo: error) { [weak self] retryResult in
                switch retryResult {
                case .retry:
                    print("Repeating request that ended in error:", error)
                    self?.makeConcurrentNetworkRequest(with: request, networkResponse: networkResponse, continuation: continuation)
                case .doNotRetry:
                    print("Choosing not to repeat the request.")
                }
            }
        }
    }
}
