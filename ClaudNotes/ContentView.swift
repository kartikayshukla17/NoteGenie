//
//  ContentView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var notesViewModel = NotesViewModel()
    @State private var showingOnboarding = false
    
    var body: some View {
        // Always show the main app without authentication
        MainTabView()
            .environmentObject(notesViewModel)
            .onAppear {
                // Check if this is the first launch
                let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
                if !hasLaunchedBefore {
                    showingOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(isShowingOnboarding: $showingOnboarding)
                    .environmentObject(notesViewModel)
            }
    }
}

#Preview {
    ContentView()
}