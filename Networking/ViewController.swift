//
//  ViewController.swift
//  Networking
//
//  Created by Ivan Stajcer on 09.03.2022..
//

import UIKit

class ViewController: UIViewController {
    // MARK: - Properties
    private lazy var reqButton = UIButton()
    private lazy var reqFailureButton = UIButton()
    private var authenticationNetworkManager = NetworkManager(baseUrl: ConfigurationProvider.shared.urlAuth, shouldLogTraffic: false)
    private var devicesNetworkManager = NetworkManager(baseUrl: ConfigurationProvider.shared.urlDevices, interceptor: CustomInterceptor())
    
    // MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        view.addSubview(reqButton)
        view.addSubview(reqFailureButton)
        view.backgroundColor = .orange
        reqButton.addTarget(self, action: #selector(onReqSuccessTap), for: .touchUpInside)
        reqButton.setTitle("GOOD", for: .normal)
        reqButton.backgroundColor = .blue
        reqButton.translatesAutoresizingMaskIntoConstraints = false
        reqFailureButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reqButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            reqButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            reqFailureButton.topAnchor.constraint(equalTo: reqButton.topAnchor, constant: 100),
            reqFailureButton.leadingAnchor.constraint(equalTo: reqButton.leadingAnchor)

        ])
        reqFailureButton.addTarget(self, action: #selector(onReqFailureTap), for: .touchUpInside)
        reqFailureButton.setTitle("FAILURE", for: .normal)
        reqFailureButton.backgroundColor = .red

    }

    @objc func onReqSuccessTap() {
        Task {
            var authReq = AuthRequest()
            authReq.createBody(username: "ivan.stajcer@gmail.com", password: "")
            let response = await authenticationNetworkManager.executeConcurrently(authReq, decodeWith: TokenModel.self)
            let accesToken = response.model?.accessToken ?? ""
            storeTokenToUserDefaults(accesToken)
        }
    }
    
    @objc func onReqFailureTap() {
        Task {
            let devicesReq = DevicesListRequest()
            let _ = await devicesNetworkManager.executeConcurrently(devicesReq)
        }
    }
    
    func storeTokenToUserDefaults(_ token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "token")
    }
}

// I left concurrent request qiwthh checked continuation for now.
/*
 CheckedContinuation performs runtime checks for missing or multiple resume operations. UnsafeContinuation avoids enforcing these invariants at runtime because it aims to be a low-overhead mechanism for interfacing Swift tasks with event loops, delegate methods, callbacks, and other non-async scheduling mechanisms. However, during development, the ability to verify that the invariants are being upheld in testing is important. Because both types have the same interface, you can replace one with the other in most circumstances, without making other changes.
 */


