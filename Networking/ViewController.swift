//
//  ViewController.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import UIKit

class ViewController: UIViewController {
    private var networkManager = NetworkManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkManager.setInterceptor(to: CustomInterceptor())
        Task {
            await makeAuthRequest()
        }
    }
    
    func makeAuthRequest() async {
        var authReq = AuthRequest()
        authReq.createBody(username: "ivan.stajcer@gmail.com", password: "@Cobe1234")
        let response = await networkManager.executeConcurrently(authReq)
        print("Response json: ", response.jsonResponse ?? "")
    }
    
    func makeDevicesListRequest() {
        let deviceReq = DevicesListRequest()
        networkManager.execute(deviceReq).handleError { failure in
            print("Failure is: ", failure)
        }.responseJson { response in
            print("Response is: \n", response ?? "")
        }
    }
}

// unckecked??

class CustomInterceptor: Interceptor {
    func adapt(urlRequest: URLRequest, networkRequest: NetworkRequestProtocol, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        print("******** INCOMING REQUEST *********")
        print("Making a request with: ", urlRequest)
        print("Headers: ", urlRequest.allHTTPHeaderFields ?? "")
        if let data = urlRequest.httpBody, let jsonBody = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
            print("Req body: ",  jsonBody)
        }
        print("***********************************\n")
        completion(.success(urlRequest))
    }
    
    func retry(_ request: URLRequest, networkRequest: NetworkRequestProtocol, _ response: URLResponse?, dueTo error: Error?, completion: @escaping (RetryResult) -> Void) {
        if let response = response as? HTTPURLResponse,
           (500...599).contains(response.statusCode) {
            completion(.retry)
        } else {
            return completion(.doNotRetry)
        }
    }
}

