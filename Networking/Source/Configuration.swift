//
//  Configuration.swift
//  Networking
//
//  Created by Ivan Stajcer on 06.06.2022..
//
import Foundation

enum Configuration: String {
    case staging
    case production
}

class ConfigurationProvider {
    // MARK: - Properties
    static let shared: ConfigurationProvider = ConfigurationProvider()
    let baseHeadersAuth = ["Content-Type" : "application/x-www-form-urlencoded"]
    let baseHeaders = ["Content-Type" : "application/json"]
    let loginGrantType = "password";
    let refreshTokenGrantType = "refresh_token";
    private let stageClientId = "";
    private let stageClientSecret = "";
    private let stageScope =
    "";
    private let prodClientId = "";
    private let prodClientSecret = "";
    private let prodScope = "";
    private let configUserDefaultsKey = ""
    
    // MARK: - Current Configuration
    private var current: Configuration {
        guard let rawValue = Bundle.main.infoDictionary?["Configuration"] as? String else {
            fatalError("No Configuration Found")
        }
        guard let configuration = Configuration(rawValue: rawValue.lowercased()) else {
            fatalError("Invalid Configuration")
        }
        return configuration
    }
    
    
    // MARK: - Computed properties
    var urlDevices: String {
        switch current {
        case .staging:
            return "https:"
        case .production:
            return "https:"
        }
    }
    
    var urlAuth: String {
        switch current {
        case .staging:
            return "https://..net/"
        case .production:
            return ""
        }
    }
    
    var socketUrl: String {
        switch current {
        case .staging:
            return "wss://"
        case .production:
            return "wss://"
        }
    }
    
    var clientSecret: String {
        switch current {
        case .staging:
            return stageClientSecret
        case .production:
            return prodClientSecret
        }
    }
    
    var clientId: String {
        switch current {
        case .staging:
            return stageClientId
        case .production:
            return prodClientId
        }
        
    }
    
    var scope: String {
        switch current {
        case .staging:
            return stageScope
        case .production:
            return prodScope
        }
        
    }
}


