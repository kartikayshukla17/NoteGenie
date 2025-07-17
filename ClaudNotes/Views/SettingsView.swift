//
//  SettingsView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import CoreHaptics

struct SettingsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @StateObject private var apiStatusChecker = APIStatusChecker()
    @State private var showingAPISettings = false
    @State private var showingAbout = false
    @State private var showingExportOptions = false
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                List {
                    // Profile Section
                    Section {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .symbolEffect(.pulse, options: .repeating.speed(0.7), value: appearAnimation)
                                )
                                .opacity(appearAnimation ? 1 : 0)
                                .scaleEffect(appearAnimation ? 1 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ClaudNotes User")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(x: appearAnimation ? 0 : -10)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                                
                                Text("\(notesViewModel.notes.count) notes created")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(x: appearAnimation ? 0 : -10)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    
                    // API Configuration
                    Section("API Configuration") {
                        // API Status Indicator
                        HStack {
                            Image(systemName: apiStatusChecker.allConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(apiStatusChecker.allConfigured ? .green : .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Status")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(apiStatusChecker.configurationMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        SettingsRow(
                            icon: "key.fill",
                            title: "API Keys",
                            subtitle: "Configure Gemini & YouTube APIs",
                            color: .blue
                        ) {
                            showingAPISettings = true
                        }
                        
                        // Supabase settings commented out for MVP
                        // SettingsRow(
                        //     icon: "cloud.fill",
                        //     title: "Supabase",
                        //     subtitle: "Database connection settings",
                        //     color: .green
                        // ) {
                        //     // TODO: Implement Supabase settings
                        // }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Data Management
                    Section("Data Management") {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            title: "Export Notes",
                            subtitle: "Export all notes as PDF or JSON",
                            color: .orange
                        ) {
                            showingExportOptions = true
                        }
                        
                        SettingsRow(
                            icon: "arrow.clockwise",
                            title: "Sync Data",
                            subtitle: "Sync with cloud storage",
                            color: .purple
                        ) {
                            // TODO: Implement sync
                        }
                        
                        SettingsRow(
                            icon: "trash.fill",
                            title: "Clear All Data",
                            subtitle: "Delete all local notes",
                            color: .red
                        ) {
                            clearAllData()
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // App Information
                    Section("About") {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About ClaudNotes",
                            subtitle: "Version 1.0.0",
                            color: .gray
                        ) {
                            showingAbout = true
                        }
                        
                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate App",
                            subtitle: "Leave a review on the App Store",
                            color: .yellow
                        ) {
                            // TODO: Implement App Store rating
                        }
                        
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            subtitle: "Get help or report issues",
                            color: .mint
                        ) {
                            // TODO: Implement contact support
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .scrollContentBackground(.hidden)
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                prepareHaptics()
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
        }
        .sheet(isPresented: $showingAPISettings) {
            APISettingsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }
    
    private func playHapticFeedback(_ type: HapticFeedbackType = .light) {
        switch type {
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func clearAllData() {
        playHapticFeedback(.medium)
        
        let alert = UIAlertController(
            title: "Clear All Data",
            message: "This will permanently delete all your notes. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            self.playHapticFeedback(.error)
            notesViewModel.notes.removeAll()
            UserDefaults.standard.removeObject(forKey: AppConstants.Keys.savedNotes)
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var animate = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                    )
                    .symbolEffect(.bounce, options: .speed(1.5), value: animate)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animate = true
            }
        }
    }
}

struct APISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var geminiAPIKey = ""
    @State private var youtubeAPIKey = ""
    @State private var appearAnimation = false
    // Supabase fields commented out for MVP
    // @State private var supabaseURL = ""
    // @State private var supabaseKey = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                Form {
                    Section("Gemini AI") {
                        SecureField("API Key", text: $geminiAPIKey)
                        
                        Text("Get your free API key from Google AI Studio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    Section("YouTube Data API") {
                        SecureField("API Key", text: $youtubeAPIKey)
                        
                        Text("Get your API key from Google Cloud Console")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Supabase section commented out for MVP
                    // Section("Supabase") {
                    //     TextField("Project URL", text: $supabaseURL)
                    //     SecureField("Anon Key", text: $supabaseKey)
                    //     
                    //     Text("Configure your Supabase project for cloud sync")
                    //         .font(.caption)
                    //         .foregroundColor(.secondary)
                    // }
                    // .listRowBackground(
                    //     RoundedRectangle(cornerRadius: 12)
                    //         .fill(.ultraThinMaterial)
                    // )
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        saveAPIKeys()
                        dismiss()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .onAppear {
                loadAPIKeys()
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
        }
        .onAppear {
            loadAPIKeys()
        }
    }
    
    private func loadAPIKeys() {
        geminiAPIKey = UserDefaults.standard.string(forKey: AppConstants.Keys.geminiAPIKey) ?? ""
        youtubeAPIKey = UserDefaults.standard.string(forKey: AppConstants.Keys.youtubeAPIKey) ?? ""
        // Supabase loading commented out for MVP
        // supabaseURL = UserDefaults.standard.string(forKey: AppConstants.Keys.supabaseURL) ?? ""
        // supabaseKey = UserDefaults.standard.string(forKey: AppConstants.Keys.supabaseKey) ?? ""
    }
    
    private func saveAPIKeys() {
        UserDefaults.standard.set(geminiAPIKey, forKey: AppConstants.Keys.geminiAPIKey)
        UserDefaults.standard.set(youtubeAPIKey, forKey: AppConstants.Keys.youtubeAPIKey)
        // Supabase saving commented out for MVP
        // UserDefaults.standard.set(supabaseURL, forKey: AppConstants.Keys.supabaseURL)
        // UserDefaults.standard.set(supabaseKey, forKey: AppConstants.Keys.supabaseKey)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 32) {
                    // App Icon
                    Image(systemName: "note.text")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                        .opacity(appearAnimation ? 1 : 0)
                        .scaleEffect(appearAnimation ? 1 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                        .symbolEffect(.bounce, options: .speed(1.5), value: appearAnimation)
                    
                    VStack(spacing: 16) {
                        Text("ClaudNotes")
                            .font(.title)
                            .fontWeight(.bold)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                        
                        Text("AI-Powered Note Taking")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                        
                        Text("Version 1.0.0")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appearAnimation)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Features:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appearAnimation)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AnimatedFeatureRow(icon: "sparkles", text: "AI-powered content generation", delay: 0.6)
                            AnimatedFeatureRow(icon: "play.rectangle", text: "YouTube transcript extraction", delay: 0.7)
                            AnimatedFeatureRow(icon: "doc.text.viewfinder", text: "OCR text recognition", delay: 0.8)
                            AnimatedFeatureRow(icon: "square.and.arrow.up", text: "PDF export functionality", delay: 0.9)
                            AnimatedFeatureRow(icon: "cloud", text: "Cloud synchronization", delay: 1.0)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Made with ❤️ using SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(1.1), value: appearAnimation)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
        }
    }
}
/*
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
*/
struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    Text("Export your notes in different formats")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                    
                    VStack(spacing: 16) {
                        ExportOptionButton(
                            title: "Export as PDF",
                            subtitle: "All notes in a single PDF file",
                            icon: "doc.fill",
                            color: .red
                        ) {
                            // TODO: Implement PDF export
                        }
                        
                        ExportOptionButton(
                            title: "Export as JSON",
                            subtitle: "Raw data for backup purposes",
                            icon: "doc.text",
                            color: .blue
                        ) {
                            // TODO: Implement JSON export
                        }
                        
                        ExportOptionButton(
                            title: "Share Individual Notes",
                            subtitle: "Select specific notes to share",
                            icon: "square.and.arrow.up",
                            color: .green
                        ) {
                            // TODO: Implement individual sharing
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var animate = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color)
                    )
                    .symbolEffect(.bounce, options: .speed(1.5), value: animate)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animate)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotesViewModel())
}
