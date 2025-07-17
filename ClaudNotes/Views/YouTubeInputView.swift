//
//  YouTubeInputView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI
import CoreHaptics

struct YouTubeInputView: View {
    @Binding var note: Note
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var youtubeURL = ""
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                            .symbolEffect(.bounce, options: .speed(1.5), value: appearAnimation)
                        
                        Text("Add YouTube Content")
                            .font(.title2)
                            .fontWeight(.bold)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                        
                        Text("Enter a YouTube URL to extract the transcript and create notes")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                    }
                    .padding(.top)
                    
                    // URL Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YouTube URL")
                            .font(.headline)
                            .opacity(appearAnimation ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.4), value: appearAnimation)
                        
                        TextField("https://youtube.com/watch?v=", text: $youtubeURL)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.95)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appearAnimation)
                    }
                    .padding(.horizontal)
                    
                    // Error message if any
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This will:")
                            .font(.headline)
                        
                        FeatureRow(icon: "text.quote", text: "Extract video transcript", delay: 0.1)
                        FeatureRow(icon: "doc.text", text: "Create a note with the content", delay: 0.2)
                        FeatureRow(icon: "sparkles", text: "Ready for AI processing", delay: 0.3)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: appearAnimation)
                    
                    Spacer()
                    
                    // Process Button
                    Button(action: {
                        playHapticFeedback(.medium)
                        processYouTubeURL()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "arrow.down.doc")
                                    .padding(.trailing, 8)
                            }
                            Text(isProcessing ? "Processing..." : "Extract Content")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isProcessing || youtubeURL.isEmpty)
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: appearAnimation)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        playHapticFeedback(.light)
                        dismiss()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .onAppear {
                prepareHaptics()
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
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
    
    private func processYouTubeURL() {
        guard !youtubeURL.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                // Add a block to the note with the YouTube URL
                let block = Block(
                    type: .transcript,
                    content: "Processing YouTube transcript...",
                    metadata: BlockMetadata(imageURL: youtubeURL)
                )
                
                await MainActor.run {
                    var updatedNote = note
                    updatedNote.contentBlocks.append(block)
                    note = updatedNote
                    notesViewModel.updateNote(updatedNote)
                }
                
                // Process with YouTube API
                await notesViewModel.createNoteFromYouTube(url: youtubeURL)
                
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error processing YouTube URL: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var animate = false
    
    init(icon: String, text: String, delay: Double = 0) {
        self.icon = icon
        self.text = text
        self.delay = delay
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
                .symbolEffect(.bounce, options: .speed(1.5), value: animate)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -10)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

