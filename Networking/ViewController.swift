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
        // Do any additional setup after loading the view.
        worker.interceptor = CustomInterceptor()
        getWeatherData()
        //getWeatherDataConcurrently()
    }
    
    func  getWeatherData() {
        var request = WeatherNetworkRequest()
        var cityNames = [String]()
        let dispatchGroup = DispatchGroup()
        
        request.queryParameters = params[0]
        worker.execute(request).handleError { failure in
            print("Failure is: ", failure)
        }.responseJson { jsonResponse in
            print("Json response: \n", jsonResponse)
        }

//        for query in params {
//            dispatchGroup.enter()
//            request.queryParameters = query
//            worker.execute(request).handleError { failure in
//                print("Failure is: ", failure)
//                dispatchGroup.leave()
//            }.responseJson { jsonResponse in
//                print("Json response: \n", jsonResponse)
//                dispatchGroup.leave()
//            }
//            //            responseDecodable(of: SomeModel.self) { model in
//            //                guard let model = model else {
//            //                    print("Model is nil.")
//            //                    return
//            //                }
//            //                dispatchGroup.leave()
//            //                cityNames.append(model.name)
//            //                print("Model: ", model)
//            //            }
//        }
        
        dispatchGroup.notify(queue: .main) {
            print("Cities: ", cityNames)
        }
        
    }
    
    func  getWeatherDataConcurrently() {
        let request = WeatherNetworkRequest()
        Task {
            let response = await worker.executeConcurrently(request)
            print("JSON response: \n", response.jsonResponse ?? "")
            print("Error response: ", response.failure ?? "")
        }
    }
}

struct SomeModel: Codable {
    let name: String
}

class CustomInterceptor: Interceptor {
    func adapt(urlRequest: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var newRequest = urlRequest
        print("I am adapting this req.... ")
        completion(.success(newRequest))
    }
    
    func retry(_ request: URLRequest, _ response: URLResponse?, dueTo error: Error?, completion: @escaping (RetryResult) -> Void) {
        let response = response as? HTTPURLResponse
        //Retry for 5xx status codes
        if
            let statusCode = response?.statusCode,
            (500...599).contains(statusCode) {
            completion(.retry)
        } else {
            return completion(.retry)
        }
    }
}

