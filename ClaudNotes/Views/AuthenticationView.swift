//
//  AuthenticationView.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSignUp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Glassmorphic background matching the app's style
                GlassmorphicBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section with enhanced styling
                        VStack(spacing: 24) {
                            // App icon with glassmorphic effect
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 120, height: 120)
                                    .overlay {
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    }
                                    .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "note.text.badge.plus")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(.purple.gradient)
                                    .symbolEffect(.bounce, value: showingSignUp)
                            }
                            .padding(.top, 40)
                            
                            VStack(spacing: 12) {
                                Text("ClaudNotes")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("Your intelligent note-taking companion")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 50)
                        
                        // Authentication card
                        VStack(spacing: 0) {
                            if showingSignUp {
                                SignUpView(authViewModel: authViewModel)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                SignInView(authViewModel: authViewModel)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                }
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, 20)
                        
                        // Toggle between sign in and sign up
                        HStack(spacing: 8) {
                            Text(showingSignUp ? "Already have an account?" : "Don't have an account?")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Button(showingSignUp ? "Sign In" : "Sign Up") {
                                HapticFeedback.light()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showingSignUp.toggle()
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        Capsule()
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    }
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .ignoresSafeArea()
        .alert("Authentication Error", isPresented: $authViewModel.isShowingAlert) {
            Button("OK") { 
                HapticFeedback.error()
            }
        } message: {
            Text(authViewModel.alertMessage)
        }
    }
}

#Preview {
    AuthenticationView()
}