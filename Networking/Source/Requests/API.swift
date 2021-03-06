//
//  API.swift
//  Networking
//
//  Created by Ivan Stajcer on 05.04.2022..
//

import Foundation

struct API {
    static let baseUrlAuth = "https://alkogtidentity.azurewebsites.net/"
    static let baseUrlStage = "https://stage.al-ko.com/v1/iot/"
    
    struct Auth {
        static let stageGrantType = "password"
        static let stageClientId = "inTOUCH4"
        static let stageClientSecret = "NFIAOfrwjhr289u41!Ndo"
        static let stageScope = "alkoCustomerId alkoCulture offline_access introspection alkoGroups"
    }
}
