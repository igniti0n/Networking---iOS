//
//  ViewController.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import UIKit

class ViewController: UIViewController {
    private var worker = Worker()
    
    private let params: [[String : String]] = [["lat" : "45.5550", "lon" : "18.6955", "appid" : "33a595b1052037a58ebbd6503b0303ac"],["lat" : "40.5550", "lon" : "19.6955", "appid" : "33a595b1052037a58ebbd6503b0303ac"],["lat" : "22.5550", "lon" : "16.6955", "appid" : "33a595b1052037a58ebbd6503b0303ac"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        worker.interceptor = CustomInterceptor()
        Task {
            await makeAuthRequest()
        }
    }
    
    func makeAuthRequest() async {
        var authReq = AuthRequest()
        authReq.createBody(username: "ivan.stajcer@gmail.com", password: "@Cobe1234")
        let response = await worker.executeConcurrently(authReq)
        print("Response json: ", response.jsonResponse)
//        worker.execute(authReq).handleError { failure in
//            print("Failure is: ", failure)
//        }.responseJson { response in
//            print("Response is: \n", response)
//        }
    }
    
    
    func makeDevicesListRequest() {
        var authReq = DevicesListRequest()
        worker.interceptor = CustomInterceptor()
        worker.execute(authReq).handleError { failure in
            print("Failure is: ", failure)
        }.responseJson { response in
            print("Response is: \n", response)
        }
    }
}

class CustomInterceptor: Interceptor {
    func adapt(urlRequest: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        print("******** INCOMING REQUEST ***********************\n")

        print("Making a request with: ", urlRequest)
        print("Headers: ", urlRequest.allHTTPHeaderFields)
        if let data = urlRequest.httpBody {
            print("req body: ", try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed))
        }
        print("\n*******************************\n")
            
//        var newRequest = urlRequest
//        let token = "Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjhERTZDNjREMjhDNDRDMzY2NDdCQjIxMjAwRkI1RTU0QzVBQTcwREQiLCJ0eXAiOiJhdCtqd3QiLCJ4NXQiOiJqZWJHVFNqRVREWmtlN0lTQVB0ZVZNV3FjTjAifQ.eyJuYmYiOjE2NDkxNTMyNzIsImV4cCI6MTY0OTE1MzM5MiwiaXNzIjoiaHR0cHM6Ly9hbGtvZ3RpZGVudGl0eS5henVyZXdlYnNpdGVzLm5ldCIsImF1ZCI6ImludHJvc3BlY3Rpb24iLCJjbGllbnRfaWQiOiJpblRPVUNINCIsInN1YiI6ImVmNzNjMDA4LTJiMGQtNGUwNS04NWM3LTlhMDZjMDFlNGI4YyIsImF1dGhfdGltZSI6MTY0OTE1MzI3MiwiaWRwIjoibG9jYWwiLCJBc3BOZXQuSWRlbnRpdHkuU2VjdXJpdHlTdGFtcCI6IlVYSjRMSlk0NldOWUpYTlJaUlZSUU5RMkxBQ0xNSVdHIiwicHJlZmVycmVkX3VzZXJuYW1lIjoieW91Y2F0dGVzdDU1QGdtYWlsLmNvbSIsIm5hbWUiOiJ5b3VjYXR0ZXN0NTVAZ21haWwuY29tIiwiZW1haWwiOiJ5b3VjYXR0ZXN0NTVAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJhbGtvQ3VzdG9tZXJJZCI6IjAwMDgwODYyMzEiLCJhbGtvQ3VsdHVyZSI6IkRFIiwiYWxrb0dyb3VwcyI6WyJDVVNUT01FUiJdLCJzY29wZSI6WyJhbGtvQ3VsdHVyZSIsImFsa29DdXN0b21lcklkIiwiYWxrb0dyb3VwcyIsImludHJvc3BlY3Rpb24iLCJvZmZsaW5lX2FjY2VzcyJdLCJhbXIiOlsicGFzc3dvcmQiXX0.Bj8Jw9AzYR7Z-F0c70Oq3QrNh4LqzO8UuKv9grdtxIbbnyeLqy6zG4XstSkqVfS1ljLcnrEb3BtvBOcV_LCYbfZ3kfX5xHce-i3XKYKCh5Kmvn9CpwPVsKGSbFVLKNNx_2SueQM7lY09QKqV_kN7O2DUpwqEsARDDqvvkLcDeylowF0cxb7AFiTvHU4qGqKaGQ6yeUjB-k2qdkOp0COSgsi-WbuEleY03mES3zR7ThogXFHl-ozCFLpxHhTsJAamIlDBP0D77FVTq27v51f76B3TUwKvqmeo9XgMdq6XHuYF5tt1Bb7H1meX28MjRlFzrl3oMFZyG1ZgG8jOCtlZ0Q"
//        newRequest.addValue(token, forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }
    
    func retry(_ request: URLRequest, _ response: URLResponse?, dueTo error: Error?, completion: @escaping (RetryResult) -> Void) {
        let response = response as? HTTPURLResponse
        //Retry for 5xx status codes
        if
            let statusCode = response?.statusCode,
            (500...599).contains(statusCode) {
            completion(.retry)
        } else {
            return completion(.doNotRetry)
        }
    }
}

