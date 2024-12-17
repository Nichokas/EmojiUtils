//
//  AuthenticationService.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import Foundation
import CryptoKit

class AuthenticationService: ObservableObject {
    private let baseURL = "http://127.0.0.1:8080"
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    @Published var isAuthenticated = false
    @Published var currentIdentity: DigitalIdentity?
    @Published var error: String?
    
    private var apiKey: String?
    private var authToken: String?
    
    struct DigitalIdentity: Codable {
        let id: String
        let username: String
        let device_id: String
        let created_at: Int64
    }
    
    struct AuthRequest: Codable {
        let device_id: String
        let challenge_response: String
        let timestamp: Int64
    }
    
    struct AuthResponse: Codable {
        let token: String
        let identity: DigitalIdentity
    }
    
    struct RegisterResponse: Codable {
        let api_key: String
    }
    
    func register(username: String) async throws {
        let identity = DigitalIdentity(
            id: UUID().uuidString,
            username: username,
            device_id: deviceId,
            created_at: Int64(Date().timeIntervalSince1970)
        )
        
        let url = URL(string: "\(baseURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(identity)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RegisterResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.apiKey = response.api_key
        }
    }
    
    func authenticate() async throws {
        guard let apiKey = self.apiKey else {
            throw AuthError.noApiKey
        }
        
        let timestamp = Int64(Date().timeIntervalSince1970)
        let challengeString = "\(deviceId):\(timestamp)"
        
        let key = SymmetricKey(data: apiKey.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(
            for: challengeString.data(using: .utf8)!,
            using: key
        )
        let challengeResponse = Data(signature).base64EncodedString()
        
        let authRequest = AuthRequest(
            device_id: deviceId,
            challenge_response: challengeResponse,
            timestamp: timestamp
        )
        
        let url = URL(string: "\(baseURL)/auth")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(authRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.authToken = response.token
            self.currentIdentity = response.identity
            self.isAuthenticated = true
        }
    }
    
    enum AuthError: Error {
        case noApiKey
    }
}
