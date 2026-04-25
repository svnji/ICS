//
//  LoginViewModel.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import Foundation

final class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isFormValid: Bool {
        email.contains("@") && password.count >= 6
    }
    
    func login() async throws {
        try await AuthService.shared.login(email: email, password: password)
    }
}
