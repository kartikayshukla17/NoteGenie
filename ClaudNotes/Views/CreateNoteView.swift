//
//  CreateNoteView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import CoreHaptics
// No need to explicitly import ButtonStyles.swift as it's part of the same module

struct CreateNoteView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var showingNoteDetail = false
    @State private var showingYouTubeInput = false
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var tempNote = Note(title: "YouTube Note", userId: "default_user")
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                            .symbolEffect(.bounce, options: .speed(1.5), value: appearAnimation)
                        
                        VStack(spacing: 8) {
                            Text("Create New Note")
                                .font(.title)
                                .fontWeight(.bold)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                            
                            Text("Choose how you'd like to start")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                        }
                    }
                    
                    // Creation Options
                    VStack(spacing: 16) {
                        CreateOptionButton(
                            title: "Blank Note",
                            subtitle: "Start with a clean slate",
                            icon: "doc.text",
                            gradient: [.blue, .cyan]
                        ) {
                            playHapticFeedback(.medium)
                            createBlankNote()
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appearAnimation)
                        
                        CreateOptionButton(
                            title: "YouTube Video",
                            subtitle: "Generate notes from video transcript",
                            icon: "play.rectangle.fill",
                            gradient: [.red, .orange]
                        ) {
                            playHapticFeedback(.medium)
                            showingYouTubeInput = true
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appearAnimation)
                        
                        CreateOptionButton(
                            title: "From Image",
                            subtitle: "Extract text using OCR",
                            icon: "photo.on.rectangle",
                            gradient: [.green, .mint]
                        ) {
                            playHapticFeedback(.medium)
                            showingImagePicker = true
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: appearAnimation)
                        
                        CreateOptionButton(
                            title: "From Document",
                            subtitle: "Import PDF or text file",
                            icon: "doc.fill",
                            gradient: [.purple, .pink]
                        ) {
                            playHapticFeedback(.medium)
                            showingDocumentPicker = true
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: appearAnimation)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingNoteDetail) {
            if let selectedNote = notesViewModel.selectedNote {
                NoteDetailView(note: selectedNote)
            }
        }
        .sheet(isPresented: $showingYouTubeInput) {
            YouTubeInputView(note: $tempNote)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView()
        }
    }
    
    private func createBlankNote() {
        notesViewModel.createNote()
        showingNoteDetail = true
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
}

// Define a custom button style with a different name to avoid redeclaration
struct CreateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CreateOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                
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
        .buttonStyle(CreateButtonStyle())
    }
}

#Preview {
    CreateNoteView()
        .environmentObject(NotesViewModel())
}
