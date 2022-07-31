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
    case statusCode(StatusCode)
    case responseNotHTTP
    case urlRequestConstruction
    case tokenExpired
    case tokenUnknown
    case decoding
    case error
}

enum StatusCode {
    case notFound
    case badRequest
    case unauthorized
    case forbidden
    case notAllowed
    case timeout
    case serverError
    case other(Int)
    
    init(code: Int) {
        switch code {
        case 500..<600: self = .serverError
        case 404: self = .notFound
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 405: self = .notAllowed
        case 408: self = .timeout
        default: self = .other(code)
        }
    }
    
}

final class NetworkManager {
    // MARK: - Properties
    private var baseUrl: String
    private var interceptor: Interceptor?
    private var jsonResponse: JSONResponse?
    private var failure: ErrorResponse?
    private var networkResponse: NetworkResponse?
    private var repeatCount = 1
    private var shouldLogTraffic: Bool
    
    // MARK: - init
    init(baseUrl: String, interceptor: Interceptor? = nil, shouldLogTraffic: Bool = true) {
        self.baseUrl = baseUrl
        self.interceptor = interceptor
        self.shouldLogTraffic = shouldLogTraffic
    }
}

// MARK: - Public methods
extension NetworkManager {
    func setInterceptor(to interceptor: Interceptor) {
        self.interceptor = interceptor
    }
    
    func removeInterceptor() {
        interceptor = nil
    }
    
    func setShouldLogTraffic(to shouldLog: Bool) {
        shouldLogTraffic = shouldLog
    }
    
    func executeConcurrently(_ networkRequest: NetworkRequestProtocol) async -> NetworkResponse {
        let response: NetworkResponse =  await withCheckedContinuation { continuation in
            var networkResponse = NetworkResponse()
            guard let urlRequest = constructURLRequest(networkRequest) else {
                networkResponse.failure = NetworkFailure.urlRequestConstruction
                finishReturning(response: networkResponse, for: continuation)
                return
            }
            interceptor?.adapt(urlRequest: urlRequest, networkRequest: networkRequest, completion: { [weak self] result in
                switch result {
                case .success(let request):
                    self?.makeConcurrentNetworkRequest(with: request, for: networkRequest, continuation: continuation)
                case .failure(let failure):
                    print("Error while adapting request: ", failure)
                    networkResponse.failure = failure
                    self?.handleErrorConcurrently(networkResponse: networkResponse, urlRequest, networkRequest: networkRequest, continuation: continuation)
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
                if let _ = response.failure {
                    continuation.resume(returning: (response, nil))
                    return
                }
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
        guard var components = URLComponents(string: baseUrl + request.path) else { return nil }
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
        if let requestBody = request.body {
            // Construct body as json data or urlEncoded data
            switch request.resourceEncoding {
                case .urlEncoded:
                    urlRequest.httpBody = encodeBodyToUrlEncodedData(requestBody)
                case .json:
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
    
    func makeConcurrentNetworkRequest(with urlRequest: URLRequest, for networkRequest: NetworkRequestProtocol, continuation: CheckedContinuation<NetworkResponse, Never>) {
        logOutgoingNetworkRequest(urlRequest: urlRequest, networkRequest: networkRequest)
        var networkResponse = NetworkResponse()
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            // Validate response
            self?.takeInfoFromReceivedResponse(data: data, response: response, error: error, networkResponse: &networkResponse)
            if networkResponse.failure != nil {
                //continuation.resume(returning: networkResponse)
                self?.handleErrorConcurrently(networkResponse: networkResponse, urlRequest, networkRequest: networkRequest, continuation: continuation)
                return
            }
            // Generate JSON object
            guard let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
                self?.finishReturning(response: networkResponse, for: continuation)
                return
            }
            // All good, return json object
            networkResponse.jsonResponse = jsonObject
            self?.finishReturning(response: networkResponse, for: continuation)
        }
        task.resume()
    }
    
    func takeInfoFromReceivedResponse(data: Data?, response: URLResponse?, error: Error?,  networkResponse: inout NetworkResponse) {
        networkResponse.data = data
        networkResponse.error = error
        guard let httpResponse = response as? HTTPURLResponse else {
                networkResponse.failure = .responseNotHTTP
                return
        }
        networkResponse.statusCode = httpResponse.statusCode
        if !(200...299).contains(httpResponse.statusCode) {
            networkResponse.failure = .statusCode(StatusCode.init(code: httpResponse.statusCode))
        }
    }
    
    func handleErrorConcurrently(networkResponse: NetworkResponse,  _ urlRequest: URLRequest, networkRequest: NetworkRequestProtocol, continuation: CheckedContinuation<NetworkResponse, Never>) {
        logNetworkError(networkRequest: networkRequest, response: networkResponse)
        guard let interceptor = interceptor else {
            finishReturning(response: networkResponse, for: continuation)
            return
        }
        if(repeatCount < 0) {
            print("🛑 Will not repeat anymore, repeat count < 1")
            repeatCount = 1
            finishReturning(response: networkResponse, for: continuation)
        } else {
            repeatCount -= 1
            interceptor.retry(networkRequest: networkRequest, response: networkResponse) { [weak self] retryResult in
                switch retryResult {
                case .retry:
                    interceptor.adapt(urlRequest: urlRequest, networkRequest: networkRequest, completion: { [weak self] result in
                        switch result {
                        case .success(let request):
                            print("↩️ Repeating request that ended in error:", networkResponse.failure ?? "")
                            self?.makeConcurrentNetworkRequest(with: request, for: networkRequest, continuation: continuation)
                        case .failure(let failure):
                            print("❌ Error while adapting request: ", failure)
                            self?.handleErrorConcurrently(networkResponse: networkResponse, urlRequest, networkRequest: networkRequest, continuation: continuation)
                        }
                    })
                case .doNotRetry:
                    self?.repeatCount = 1
                    print("🛑 Choosing not to repeat the request.")
                    continuation.resume(returning: networkResponse)
                }
            }
        }
    }
    
    func finishReturning(response: NetworkResponse, for continuation: CheckedContinuation<NetworkResponse, Never>) {
        logIncomingNetworkResponse(response: response)
        continuation.resume(returning: response)
    }
    
    func logOutgoingNetworkRequest(urlRequest: URLRequest, networkRequest: NetworkRequestProtocol) {
        guard shouldLogTraffic == true else { return }
        print("↗️↗️ SENDING REQUEST ↗️↗️")
        print("Full path: ", urlRequest)
        if let headers = urlRequest.allHTTPHeaderFields {
            print("Headers: ", headers)
        }
        if let body =  networkRequest.body {
            print("Body: ", body)
        }
        print("HTTP Method: ", networkRequest.httpMethod)
        print("Encoding: ", networkRequest.resourceEncoding)
        print("↗️ * * * * * * * * * * ↗️")
    }
    
    func logIncomingNetworkResponse(response: NetworkResponse) {
        guard shouldLogTraffic == true else { return }
        print("↙️↙️ RESPONSE ↙️↙️")
        print("Response: ", response.jsonResponse ?? "EMPTY")
        print("Status code: ", response.statusCode ?? "UNKNOWN")
        if let failure = response.failure {
            print("❌ Failure: ", failure)
        }
        print("↙️ * * * * * * * ↙️")
    }
    
    func logNetworkError(networkRequest: NetworkRequestProtocol, response: NetworkResponse) {
        guard shouldLogTraffic == true else { return }
        print("❌❌ REQUEST FAILED ❌❌")
        print("Full path: ", networkRequest.path)
        print("Query params: ", networkRequest.path)
        print("Headers: ", networkRequest.headers)
        print("Body: ", networkRequest.body ?? "Empty.")
        print("HTTP Method: ", networkRequest.httpMethod)
        print("Encoding: ", networkRequest.resourceEncoding)
        print("Status code: ", response.statusCode ?? "UNKNOWN")
        print("❌ * * * * * * * * * * ❌")
    }
}

