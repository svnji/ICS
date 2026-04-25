//
//  RegisterView.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI

struct RegisterView: View {
    
    @StateObject private var vm = RegisterViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View { ScrollView {
        GeometryReader { geo in
            
            ZStack {
                
                VStack(spacing: 0) {    
                    
                    Image("Sign In-011")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Start your healthy sleep journey with ICS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .offset(x: -45)
                    
                    VStack(spacing: 16) {
                        
                        CustomRegisterTextField(
                            placeholder: "Full Name",
                            systemImage: "person.fill",
                            text: $vm.name
                        )
                        
                        CustomRegisterTextField(
                            placeholder: "Email",
                            systemImage: "envelope.fill",
                            text: $vm.email
                        )
                        
                        CustomRegisterTextField(
                            placeholder: "Password",
                            systemImage: "lock.fill",
                            text: $vm.password,
                            isSecure: true
                        )
                        
                        CustomRegisterTextField(
                            placeholder: "Confirm Password",
                            systemImage: "lock.fill",
                            text: $vm.confirmPassword,
                            isSecure: true
                        )
                        
                        DateOfBirthField(date: $vm.dateOfBirth)
                    }
                    .padding(.top, 20)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(height: 120)
                            .foregroundStyle(Color(.systemGray6))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            
                            Text("Password must contain:")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                Text("At least 8 characters")
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                Text("One uppercase letter")
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                Text("One number or special character")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    
                    // MARK: REGISTER BUTTON (FIXED SAFE)
                    Button {
                        Task {
                            await handleRegister()
                        }
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Text("Register")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(vm.isFormValid ? Color.orange : Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .disabled(!vm.isFormValid || vm.isLoading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 8)
                    }
                    
                    
                    HStack {
                        Text("Already have an account?")
                        
                        Button {
                            router.pop()
                        } label: {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 10)
                    
                }
                Image("sleepy owl  1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .position(
                        x: geo.size.width * 0.75,
                        y: geo.size.height * 16
                    )
            }
        }
    }
}
    
    // MARK: - SAFE REGISTER FLOW
    private func handleRegister() async {
        
        guard vm.isFormValid else {
            vm.errorMessage = "Please fill all fields correctly"
            return
        }
        
        vm.isLoading = true
        vm.errorMessage = nil
        
        do {
            try await vm.register()
            
            // small delay to sync Firebase state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                router.resetToRoot(.home)
            }
            
        } catch {
            vm.errorMessage = error.localizedDescription
        }
        
        vm.isLoading = false
    }
}
    // MARK: - Custom TextField
struct CustomRegisterTextField: View {
    
    var placeholder: String
    var systemImage: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(height: 50)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3))
        )
        .padding(.horizontal)
    }
}
    // MARK: - Date of Birth Field
struct DateOfBirthField: View {
    
    @Binding var date: Date
    @State private var showPicker = false
    
    var body: some View {
        VStack(spacing: 10) {
            
            Button {
                showPicker.toggle()
            } label: {
                HStack {
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(formattedDate)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(height: 50)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3))
                )
                .padding(.horizontal)
            }
            
            if showPicker {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: showPicker)
    }
    
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

#Preview {
    RegisterView()
}
