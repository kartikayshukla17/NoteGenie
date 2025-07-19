//
//  SignUpView.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, email, password, confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // Welcome text with enhanced styling
            VStack(spacing: 12) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Join ClaudNotes and start organizing your thoughts")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Input fields with glassmorphic styling
            VStack(spacing: 20) {
                // Full name field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Full Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    TextField("Enter your full name", text: $fullName)
                        .textFieldStyle(GlassmorphicTextFieldStyle())
                        .textContentType(.name)
                        .focused($focusedField, equals: .fullName)
                        .onSubmit {
                            focusedField = .email
                        }
                }
                
                // Email field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(GlassmorphicTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    SecureField("Create a password", text: $password)
                        .textFieldStyle(GlassmorphicTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                    
                    // Password requirements
                    if !password.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            PasswordRequirement(
                                text: "At least 6 characters",
                                isMet: password.count >= 6
                            )
                        }
                        .padding(.top, 6)
                    }
                }
                
                // Confirm password field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(GlassmorphicTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .onSubmit {
                            Task {
                                await signUp()
                            }
                        }
                    
                    // Password match indicator
                    if !confirmPassword.isEmpty {
                        PasswordRequirement(
                            text: "Passwords match",
                            isMet: password == confirmPassword
                        )
                        .padding(.top, 6)
                    }
                }
            }
            
            // Sign up button with enhanced styling
            Button {
                HapticFeedback.light()
                Task {
                    await signUp()
                }
            } label: {
                HStack(spacing: 12) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.title3)
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.purple.gradient)
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .foregroundStyle(.white)
            }
            .disabled(!formIsValid || authViewModel.isLoading)
            .opacity(formIsValid ? 1.0 : 0.6)
            .scaleEffect(formIsValid ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formIsValid)
            
            // Divider with enhanced styling
            HStack(spacing: 16) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
                
                Text("or")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            // Google sign up button with glassmorphic styling
            Button {
                HapticFeedback.light()
                Task {
                    try await authViewModel.signInWithGoogle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image("google_logo")
                        .resizable()
                        .frame(width: 22, height: 22)
                    
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        }
                }
            }
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.6 : 1.0)
        }
    }
    
    private var formIsValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func signUp() async {
        do {
            try await authViewModel.createUser(withEmail: email, password: password, fullname: fullName)
        } catch {
            // Error handling is done in the view model
        }
    }
}

struct GlassmorphicTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    }
            }
            .foregroundStyle(.white)
            .font(.body.weight(.medium))
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(isMet ? .green : .white.opacity(0.7))
            
            Text(text)
                .font(.caption)
                .foregroundStyle(isMet ? .green : .white.opacity(0.7))
        }
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel())
        .padding()
}