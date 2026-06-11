//
//  RegisterModelView.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import Foundation

final class RegisterViewModel: ObservableObject {
    
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var dateOfBirth: Date = Date()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isFormValid: Bool {
        !name.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    func register() async throws {
        try await AuthService.shared.register(email: email, password: password)
    }
}
