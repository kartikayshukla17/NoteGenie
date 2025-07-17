//
//  AddContentView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI

struct AddContentView: View {
    @Binding var note: Note
    @EnvironmentObject var notesViewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContentType: ContentType = .text
    @State private var textContent = ""
    @State private var youtubeURL = ""
    @State private var isProcessing = false
    @State private var selectedAIType: AIGenerationType = .summary
    
    enum ContentType: String, CaseIterable {
        case text = "Text"
        case youtube = "YouTube"
        case image = "Image"
        case document = "Document"
        case aiGenerated = "AI Generated"
        
        var icon: String {
            switch self {
            case .text: return "text.alignleft"
            case .youtube: return "play.rectangle"
            case .image: return "photo"
            case .document: return "doc"
            case .aiGenerated: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .blue
            case .youtube: return .red
            case .image: return .green
            case .document: return .orange
            case .aiGenerated: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    // Content Type Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ContentType.allCases, id: \.self) { type in
                                ContentTypeButton(
                                    type: type,
                                    isSelected: selectedContentType == type
                                ) {
                                    selectedContentType = type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content Input
                    VStack(spacing: 16) {
                        switch selectedContentType {
                        case .text:
                            TextInputView(content: $textContent)
                            
                        case .youtube:
                            YouTubeURLInputView(url: $youtubeURL)
                            
                        case .image:
                            ImageInputView()
                            
                        case .document:
                            DocumentInputView()
                            
                        case .aiGenerated:
                            AIGeneratedInputView(existingContent: note.contentBlocks.map { $0.content }.joined(separator: "\n"), selectedAIType: $selectedAIType)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: addContent) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text(isProcessing ? "Processing..." : "Add Content")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [selectedContentType.color, selectedContentType.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .disabled(isProcessing || !canAddContent)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Add Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canAddContent: Bool {
        switch selectedContentType {
        case .text:
            return !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .youtube:
            return !youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image, .document, .aiGenerated:
            return true
        }
    }
    
    private func addContent() {
        isProcessing = true
        
        Task {
            switch selectedContentType {
            case .text:
                await MainActor.run {
                    let block = Block(type: .text, content: textContent)
                    addBlockToNote(block)
                    isProcessing = false
                    dismiss()
                }
                
            case .youtube:
                await notesViewModel.createNoteFromYouTube(url: youtubeURL)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
                
            case .image:
                // For now, add placeholder - will be implemented with ImagePickerView integration
                await MainActor.run {
                    let block = Block(type: .ocrText, content: "Image OCR functionality will be available soon. Please use the Image Picker from the main create screen.")
                    addBlockToNote(block)
                    isProcessing = false
                    dismiss()
                }
                
            case .document:
                // For now, add placeholder - will be implemented with DocumentPickerView integration
                await MainActor.run {
                    let block = Block(type: .pdfEmbed, content: "Document import functionality will be available soon. Please use the Document Picker from the main create screen.")
                    addBlockToNote(block)
                    isProcessing = false
                    dismiss()
                }
                
            case .aiGenerated:
                if let selectedNote = notesViewModel.selectedNote {
                    await notesViewModel.generateAIContent(for: selectedNote, type: selectedAIType)
                }
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            }
        }
    }
    
    private func addBlockToNote(_ block: Block) {
        var updatedNote = note
        updatedNote.contentBlocks.append(block)
        updatedNote.updatedAt = Date()
        note = updatedNote
        notesViewModel.updateNote(updatedNote)
    }
}

struct ContentTypeButton: View {
    let type: AddContentView.ContentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(type.color, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TextInputView: View {
    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter your text")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $content)
                .font(.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(minHeight: 120)
        }
    }
}

struct YouTubeURLInputView: View {
    @Binding var url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YouTube URL")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("https://youtube.com/watch?v=...", text: $url)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            Text("We'll extract the transcript and generate notes automatically")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ImageInputView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Select an image to extract text using OCR")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Choose Image") {
                // TODO: Implement image picker
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DocumentInputView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Select a PDF or document to import")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Choose Document") {
                // TODO: Implement document picker
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AIGeneratedInputView: View {
    let existingContent: String
    @Binding var selectedAIType: AIGenerationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Generation Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AIGenerationType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedAIType = type
                    }) {
                        VStack(spacing: 8) {
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(type.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(aiTypeButtonBackground(for: type))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if existingContent.isEmpty {
                Text("Add some content to your note first to generate AI content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.yellow.opacity(0.2))
                    )
            }
        }
    }
    
    @ViewBuilder
    private func aiTypeButtonBackground(for type: AIGenerationType) -> some View {
        if selectedAIType == type {
            RoundedRectangle(cornerRadius: 12)
                .fill(.purple.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.purple, lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    let sampleNote = Note(title: "Sample Note", userId: "user1")
    return AddContentView(note: .constant(sampleNote))
        .environmentObject(NotesViewModel())
}

