//
//  LoginView.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var vm = LoginViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var auth: AuthManager
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    
                    Image("Sign In-011")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("welcome Back !!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Enter your email and password\nto continue your sleep journey")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)
                    .offset(x: -35)
                    
                    VStack(spacing: 16) {
                        
                        CustomTextField(
                            placeholder: "email@domain.com",
                            text: $vm.email,
                            isSecure: false
                        )
                        
                        CustomTextField(
                            placeholder: "password",
                            text: $vm.password,
                            isSecure: true
                        )
                    }
                    .padding(.top, 20)
                    
                    HStack {
                        Spacer()
                        Button("Forgot password?") {}
                            .font(.footnote)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Button {
                        Task { await handleLogin() }
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Continue")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .disabled(vm.isLoading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 6)
                    }
                    
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    VStack {
                        Text("Don't have an account?")
                            .font(.headline)
                        Text("Create an account to start your healthy sleep journey")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .offset(x: 40)
                    .frame(width: 190)
                    
                    Spacer()
                    
                    Button {
                        router.goTo(.register)
                    } label: {
                        Text("registration")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    Text("By clicking continue, you agree to our **Terms of service and privacy policy**")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Image("sleepy owl  1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .position(x: geo.size.width * 0.75,
                              y: geo.size.height * 0.25)
                    .allowsHitTesting(false)

                Image("owl with red funny eyes 1-020")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .position(x: geo.size.width * 0.17,
                              y: geo.size.height * 0.78)
                    .allowsHitTesting(false)            }
        }
    }
    
    private func handleLogin() async {
        guard vm.isFormValid else {
            vm.errorMessage = "Invalid email or password"
            return
        }
        vm.isLoading = true
        vm.errorMessage = nil
        do {
            try await vm.login()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                router.resetToRoot(.home)
            }
        } catch {
            vm.errorMessage = error.localizedDescription
        }
        vm.isLoading = false
    }
}

struct CustomTextField: View {
    
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            
            if isSecure {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 4)
                    .onTapGesture {
                        isPasswordVisible.toggle()
                    }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
#Preview {
    LoginView()
}
