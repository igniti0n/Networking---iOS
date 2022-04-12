//
//  ViewController.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import UIKit

class ViewController: UIViewController {
    private var authenticationNetworkManager = NetworkManager(baseUrl: API.baseUrlAuth, interceptor: CustomInterceptor())
    private var devicesNetworkManager = NetworkManager(baseUrl: API.baseUrlStage, interceptor: CustomInterceptor())

    override func viewDidLoad() {
        super.viewDidLoad()
        makeAuthRequestWithClosures()
        Task {
            await makeAuthRequestConcurrently()
        }
        makeDevicesRequest()
    }
    
    func makeAuthRequestConcurrently() async {
        var authReq = AuthRequest()
        authReq.createBody(username: "ivan.stajcer@gmail.com", password: "@Cobe1234")
        let response = await authenticationNetworkManager.executeConcurrently(authReq, decodeWith: TokenModel.self)
        print("Response json: ", response.response.jsonResponse ?? "n/a")
        print("Response model: ", response.model ?? "n/a")
    }
    
    func makeAuthRequestWithClosures() {
        var authReq =  AuthRequest()
        authReq.createBody(username: "ivan.stajcer@gmail.com", password: "@Cobe1234")
        authenticationNetworkManager.execute(authReq).handleError { failure in
            print("Failure is: ", failure)
        }.responseJson { response in
            print("Response from closure is: \n", response ?? "n/a")
        }.responseDecodable(of: TokenModel.self) { model in
            print("Response model from closure: ", model ?? "n/a")
        }
    }
    
    func makeDevicesRequest() {
        let devicesReq =  DevicesListRequest()
        devicesNetworkManager.execute(devicesReq).handleError { failure in
            print("Failure is: ", failure)
        }.responseJson { response in
            print("Response from closure is: \n", response ?? "n/a")
        }
    }
}

// I left concurrent request qiwthh checked continuation for now.
/*
 CheckedContinuation performs runtime checks for missing or multiple resume operations. UnsafeContinuation avoids enforcing these invariants at runtime because it aims to be a low-overhead mechanism for interfacing Swift tasks with event loops, delegate methods, callbacks, and other non-async scheduling mechanisms. However, during development, the ability to verify that the invariants are being upheld in testing is important. Because both types have the same interface, you can replace one with the other in most circumstances, without making other changes.
 */
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
        print("******** REQUEST FAILED *********")
        print("For request: ", networkRequest)
        print("Response is: ", response)
        if let response = response as? HTTPURLResponse,
           (500...599).contains(response.statusCode) {
            completion(.retry)
        } else {
            completion(.doNotRetry)
        }
        print("*********************************\n")
    }
}

