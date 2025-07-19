//
//  ContentView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notesViewModel = NotesViewModel()
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                // User is authenticated - show main app
                MainTabView()
                    .environmentObject(notesViewModel)
                    .environmentObject(authViewModel)
                    .onAppear {
                        // Initialize Firebase integration when user is authenticated
                        Task {
                            // Wait a moment for Firebase auth to fully initialize
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            await MainActor.run {
                                notesViewModel.initializeFirebaseIfNeeded()
                            }
                        }
                        
                        // Check if this is the first launch for this user
                        let userKey = "hasLaunchedBefore_\(authViewModel.userSession?.uid ?? "default")"
                        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: userKey)
                        if !hasLaunchedBefore {
                            showingOnboarding = true
                            UserDefaults.standard.set(true, forKey: userKey)
                        }
                    }
                    .onChange(of: authViewModel.userSession) { session in
                        // Re-initialize Firebase when authentication state changes
                        if session != nil {
                            Task {
                                await MainActor.run {
                                    notesViewModel.initializeFirebaseIfNeeded()
                                }
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showingOnboarding) {
                        OnboardingView(isShowingOnboarding: $showingOnboarding)
                            .environmentObject(notesViewModel)
                            .environmentObject(authViewModel)
                    }
            } else {
                // User is not authenticated - show authentication
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
