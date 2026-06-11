//
//  AuthManager.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import FirebaseAuth
import Foundation

final class AuthManager: ObservableObject {
    
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    
    private var authListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = (user != nil)
            }
        }
    }
    
    deinit {
        if let authListener = authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }
}
