//
//  AuthService.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import Foundation
import FirebaseAuth

final class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func register(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }
}
