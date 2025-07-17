//
//  NoteDetailView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import Combine

struct NoteDetailView: View {
    @State var note: Note
    @EnvironmentObject var viewModel: NotesViewModel
    @FocusState private var isTitleFocused: Bool
    @State private var showingAddContent = false
    @State private var showingAIOptions = false
    @State private var showingYouTubeInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title TextField - Apple Notes style
            TextField("Title", text: Binding(
                get: { note.title },
                set: { 
                    note.title = $0
                    viewModel.updateNote(note)
                }
            ))
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top, 12)
            .focused($isTitleFocused)
            
            // Last updated text
            HStack {
                Text("Edited \(formatDate(note.updatedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Content Blocks
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(note.contentBlocks) { block in
                        BlockDetailView(block: block, note: $note)
                            .environmentObject(viewModel)
                    }
                    
                    // Empty space at bottom for better scrolling
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(GlassmorphicBackground())
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                // YouTube button
                Button(action: {
                    showingYouTubeInput = true
                }) {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // AI button
                Button(action: {
                    showingAIOptions = true
                }) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                // Add content button
                Button(action: {
                    showingAddContent = true
                }) {
                    Image(systemName: "plus")
                }
                
                Spacer()
                
                // Share button
                Menu {
                    Button("Export PDF", systemImage: "doc.fill") {
                        // TODO: Implement PDF export
                    }
                    
                    Button("Share", systemImage: "square.and.arrow.up") {
                        // TODO: Implement sharing
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddContent) {
            AddContentView(note: $note)
        }
        .sheet(isPresented: $showingAIOptions) {
            AIOptionsView(note: note)
        }
        .sheet(isPresented: $showingYouTubeInput) {
            YouTubeInputView(note: $note)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AIOptionsView: View {
    let note: Note
    @EnvironmentObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: String = "summary"
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    Text("Generate with AI")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose how you'd like AI to enhance your note")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        AIOptionButton(type: "summary", title: "Summary", description: "Concise overview", icon: "text.redaction", isSelected: selectedType == "summary") {
                            selectedType = "summary"
                        }
                        
                        AIOptionButton(type: "flashcards", title: "Flashcards", description: "Study cards", icon: "rectangle.stack", isSelected: selectedType == "flashcards") {
                            selectedType = "flashcards"
                        }
                        
                        AIOptionButton(type: "quiz", title: "Quiz", description: "Test questions", icon: "questionmark.circle", isSelected: selectedType == "quiz") {
                            selectedType = "quiz"
                        }
                        
                        AIOptionButton(type: "cornell", title: "Cornell Notes", description: "Cornell format", icon: "list.bullet.rectangle", isSelected: selectedType == "cornell") {
                            selectedType = "cornell"
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        isProcessing = true
                        
                        // Convert selected type string to AIGenerationType
                        let generationType: AIGenerationType
                        switch selectedType {
                        case "summary":
                            generationType = .summary
                        case "flashcards":
                            generationType = .flashcards
                        case "quiz":
                            generationType = .quiz
                        case "cornell":
                            generationType = .cornell
                        default:
                            generationType = .summary
                        }
                        
                        // Use NotesViewModel to generate AI content
                        Task {
                            await viewModel.generateAIContent(for: note, type: generationType)
                            isProcessing = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "sparkles")
                                    .padding(.trailing, 8)
                            }
                            Text(isProcessing ? "Generating..." : "Generate")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AIOptionButton: View {
    let type: String
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .purple)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.purple, .pink], 
                                               startPoint: .topLeading, 
                                               endPoint: .bottomTrailing))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .white.opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BlockDetailView: View {
    let block: Block
    @Binding var note: Note
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var isEditing = false
    @State private var editedContent: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Block Content
            switch block.type {
            case .text:
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minHeight: 100)
                        .onAppear {
                            editedContent = block.content
                        }
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    saveEditedContent()
                                    isEditing = false
                                }
                            }
                        }
                } else {
                    Text(block.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .onTapGesture(count: 2) {
                            isEditing = true
                        }
                        .contextMenu {
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteBlock()
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                
            case .markdown:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.badge.checkmark")
                            .foregroundColor(.purple)
                        
                        Text("Markdown")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    Text(block.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                deleteBlock()
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
                
            case .youtube:
                VStack(alignment: .leading, spacing: 8) {
                    if let metadata = block.metadata, let videoURL = metadata.imageURL {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.red)
                            
                            Text("YouTube Transcript")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            Link("Open Video", destination: URL(string: videoURL) ?? URL(string: "https://youtube.com")!)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 4)
                    }
                    
                    Text(block.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                deleteBlock()
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                
            case .image:
                if let metadata = block.metadata, let imageURL = metadata.imageURL {
                    VStack {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contextMenu {
                            Button(role: .destructive, action: {
                                deleteBlock()
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
            case .pdf:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.red)
                        
                        if let metadata = block.metadata, let fileName = metadata.originalFileName {
                            Text(fileName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(block.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                deleteBlock()
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                
            default:
                Text(block.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            deleteBlock()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    private func saveEditedContent() {
        if let index = note.contentBlocks.firstIndex(where: { $0.id == block.id }) {
            var updatedBlock = block
            updatedBlock.content = editedContent
            
            var updatedNote = note
            updatedNote.contentBlocks[index] = updatedBlock
            
            note = updatedNote
            viewModel.updateNote(updatedNote)
        }
    }
    
    private func deleteBlock() {
        var updatedNote = note
        updatedNote.contentBlocks.removeAll { $0.id == block.id }
        note = updatedNote
        viewModel.updateNote(updatedNote)
    }
}


