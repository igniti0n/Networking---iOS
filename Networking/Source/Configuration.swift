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
    private let stageClientId = "inTOUCH4";
    private let stageClientSecret = "NFIAOfrwjhr289u41!Ndo";
    private let stageScope =
    "alkoCustomerId alkoCulture offline_access introspection alkoGroups";
    private let prodClientId = "inTOUCH4";
    private let prodClientSecret = "dsadhi342413nknjk14";
    private let prodScope = "alkoCustomerId alkoCulture offline_access introspection alkoGroups";
    private let configUserDefaultsKey = "isStagingConfiguration"
    
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
            return "https://staging.al-ko.com/v1/iot/"
        case .production:
            return "https://api.al-ko.com/v1/iot/"
        }
    }
    
    var urlAuth: String {
        switch current {
        case .staging:
            return "https://alkogtidentity.azurewebsites.net/"
        case .production:
            return "https://idp.al-ko.com/"
        }
    }
    
    var socketUrl: String {
        switch current {
        case .staging:
            return "wss://socket-staging.al-ko.com/v1"
        case .production:
            return "wss://socket.al-ko.com/v1"
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


