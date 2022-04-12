//
//  TokenModel.swift
//  Networking
//
//  Created by Ivan Stajcer on 11.04.2022..
//

import Foundation

struct TokenModel: Codable {
    let accessToken: String
    let expireTime: Int
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
          case accessToken = "access_token"
          case expireTime = "expires_in"
          case refreshToken = "refresh_token"
    }
}
