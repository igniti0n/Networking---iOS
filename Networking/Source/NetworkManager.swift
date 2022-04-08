//
//  NetworkManager.swift
//  watch_stage WatchKit Extension
//
//  Created by Ivan Stajcer on 07.04.2022..
//
import Foundation

typealias JSONResponse = ([String : Any]?) -> Void
typealias ErrorResponse = (NetworkFailure) -> Void

enum NetworkFailure: Error {
    case statusCode
    case responseNotHTTP
    case urlRequestConstruction
    case tokenExpired
    case tokenUnknown
    case decoding
    case jsonObject
    case serverError
}

final class NetworkManager {
    // MARK: - Properties
    static var shared = NetworkManager()
    private var interceptor: Interceptor?
    private var jsonResponse: JSONResponse?
    private var failure: ErrorResponse?
    private var decodingClosure: ((Data) -> Void)?
    private var networkResponse: NetworkResponse?
    private var repeatCount = 1
    
    // MARK: - Init
    private init() {}
}

// MARK: - Public methods
extension NetworkManager {
    func setInterceptor(to interceptor: Interceptor) {
        self.interceptor = interceptor
    }
    
    func removeInterceptor() {
        interceptor = nil
    }
    
    func handleError(response: @escaping ErrorResponse) -> Self {
        failure = response
        return self
    }
    
    func responseJson(response: @escaping JSONResponse) -> Self {
        jsonResponse = response
        return self
    }
    
    func responseDecodable<T: Decodable>(of type: T.Type, response: @escaping (T?) -> Void) -> Self {
        decodingClosure = { data in
            guard let decodedObject =  try? JSONDecoder().decode(type, from: data) else {
                response(nil)
                return
            }
            response(decodedObject)
        }
        return self
    }
    
    func execute(_ networkRequest: NetworkRequestProtocol) -> Self {
        guard let urlRequest = constructURLRequest(networkRequest) else {
            failure?(.urlRequestConstruction)
            return self
        }
        interceptor?.adapt(urlRequest: urlRequest, networkRequest: networkRequest, completion: { [weak self] result in
            switch result {
            case .success(let request):
                self?.makeNetworkRequest(with: request, for: networkRequest)
            case .failure(let error):
                print("Error while adapting request: ", error)
                self?.failure?(.urlRequestConstruction)
            }
        })
        if interceptor == nil {
            makeNetworkRequest(with: urlRequest, for: networkRequest)
        }
        return self
    }
    
    func executeConcurrently(_ networkRequest: NetworkRequestProtocol) async -> NetworkResponse {
        let response: NetworkResponse =  await withCheckedContinuation { continuation in
            var networkResponse = NetworkResponse()
            guard let urlRequest = constructURLRequest(networkRequest) else {
                networkResponse.failure = .urlRequestConstruction
                continuation.resume(returning: networkResponse)
                return
            }
            interceptor?.adapt(urlRequest: urlRequest, networkRequest: networkRequest, completion: { [weak self] result in
                switch result {
                case .success(let request):
                    self?.makeConcurrentNetworkRequest(with: request, for: networkRequest, continuation: continuation)
                case .failure(let error):
                    print("Error while adapting request: ", error)
                    networkResponse.failure = .urlRequestConstruction
                    continuation.resume(returning: networkResponse)
                }
            })
            if interceptor == nil {
                makeConcurrentNetworkRequest(with: urlRequest, for: networkRequest, continuation: continuation)
            }
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
                var response = await self.executeConcurrently(request)
                guard
                    let data = response.data,
                    let model = try? JSONDecoder().decode(type, from: data) else {
                        response.failure = .decoding
                        continuation.resume(returning: (response, nil))
                        return
                    }
                continuation.resume(returning: (response, model))
            }
        }
        return networkResponse
    }
}

// MARK: - Private methods
private extension NetworkManager {
    func constructURLRequest(_ request: NetworkRequestProtocol) -> URLRequest? {
        // Construct url request with base url + query params
        guard var components = URLComponents(string: request.baseUrl) else { return nil }
        if !request.queryParameters.isEmpty {
            components.queryItems = request.queryParameters.map({ query in
                URLQueryItem(name: query.key, value: query.value)
            })
        }
        guard let url = components.url else { return nil }
        var urlRequest = URLRequest(url: url)
        // Construct headers
        urlRequest.httpMethod = request.httpMethod.rawValue
        request.headers.forEach { header in
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        // Construct body as json data or urlEncoded data
        if let requestBody = request.body {
            if let contentType = urlRequest.allHTTPHeaderFields?["Content-Type"], contentType == "application/x-www-form-urlencoded" {
                urlRequest.httpBody = encodeBodyToUrlEncodedData(requestBody)
            } else {
                urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
            }
        }
        return urlRequest
    }
    
    func encodeBodyToUrlEncodedData(_ body: [String: Any]) -> Data?  {
        var formString = ""
        body.forEach { (key: String, value: Any) in
            guard let value = value as? String else { return }
            let stringPart = formString.isEmpty ? "\(key)=\(value)" : "&\(key)=\(value)"
            formString.append(contentsOf: stringPart)
        }
        return formString.data(using: .utf8)
    }
    
    func makeNetworkRequest(with urlRequest: URLRequest, for networkRequest: NetworkRequestProtocol) {
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            // Validate response
            guard let data = self?.validate(data: data, response: response, error: error, errorHandler: { [weak self] networkFailure in
                self?.handleError(error, networkFailure: networkFailure, urlRequest, networkRequest: networkRequest, response)
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
    
    func makeConcurrentNetworkRequest(with urlRequest: URLRequest, for networkRequest: NetworkRequestProtocol, continuation: CheckedContinuation<NetworkResponse, Never>) {
        var networkResponse = NetworkResponse()
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            // Validate response
            guard
                let data = self?.validate(data: data, response: response, error: error, errorHandler: { [weak self] networkFailure in
                    networkResponse.failure = networkFailure
                    self?.handleErrorConcurrently(networkResponse: networkResponse, error, urlRequest, response, networkRequest: networkRequest, continuation: continuation)
                }) else {
                    return
                }
            networkResponse.data = data
            // Generate JSON object
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data)
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
                errorHandler?(.responseNotHTTP)
                return nil
            }
        
        guard (200...299).contains(response.statusCode) else {
            errorHandler?(.statusCode)
            return nil
        }
        if let _ = error {
            errorHandler?(.serverError)
            return nil
        }
        return data
    }
    
    func handleError(_ error: Error?, networkFailure: NetworkFailure, _ request: URLRequest, networkRequest: NetworkRequestProtocol, _ reponse: URLResponse?) {
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
            interceptor.retry(request, networkRequest: networkRequest, reponse, dueTo: error) { [weak self] retryResult in
                switch retryResult {
                case .retry:
                    print("Repeating request that ended in error:", error)
                    self?.makeNetworkRequest(with: request, for: networkRequest)
                case .doNotRetry:
                    print("Choosing not to repeat the request.")
                }
            }
        }
    }
    
    func handleErrorConcurrently(networkResponse: NetworkResponse, _ error: Error?, _ request: URLRequest, _ reponse: URLResponse?,  networkRequest: NetworkRequestProtocol, continuation: CheckedContinuation<NetworkResponse, Never>) {
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
            interceptor.retry(request, networkRequest: networkRequest, reponse, dueTo: error) { [weak self] retryResult in
                switch retryResult {
                case .retry:
                    print("Repeating request that ended in error:", error)
                    self?.makeConcurrentNetworkRequest(with: request, for: networkRequest, continuation: continuation)
                case .doNotRetry:
                    print("Choosing not to repeat the request.")
                    continuation.resume(returning: networkResponse)
                }
            }
        }
    }
}

