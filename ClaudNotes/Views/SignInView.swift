//
//  SignInView.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import SwiftUI

struct SignInView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // Welcome text with enhanced styling
            VStack(spacing: 12) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Sign in to continue your note-taking journey")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Input fields with glassmorphic styling
            VStack(spacing: 20) {
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
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(GlassmorphicTextFieldStyle())
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            Task {
                                await signIn()
                            }
                        }
                }
            }
            
            // Sign in button with enhanced styling
            Button {
                HapticFeedback.light()
                Task {
                    await signIn()
                }
            } label: {
                HStack(spacing: 12) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        Text("Sign In")
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
            
            // Google sign in button with glassmorphic styling
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
        !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
    }
    
    private func signIn() async {
        do {
            try await authViewModel.signIn(email: email, password: password)
        } catch {
            // Error handling is done in the view model
        }
    }
}
/*
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
 */

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }
}

#Preview {
    SignInView(authViewModel: AuthViewModel())
        .padding()
}
