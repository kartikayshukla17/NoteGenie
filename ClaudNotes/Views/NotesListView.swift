//
//  NotesListView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import CoreHaptics

struct NotesListView: View {
    // Haptic feedback manager
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var searchText = ""
    @State private var sortOrder: NoteSortOrder = .updatedNewest
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    @State private var selectedNoteId: String? = nil
    
    // Filter parameter
    var filter: NoteFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                SearchBar(text: $searchText)
                
                Menu {
                    Button(action: {
                        sortOrder = .updatedNewest
                    }) {
                        Label("Date Edited", systemImage: "calendar")
                        if sortOrder == .updatedNewest {
                            Image(systemName: "checkmark")
                        }
                    }
                    
                    Button(action: {
                        sortOrder = .titleAZ
                    }) {
                        Label("Title", systemImage: "textformat.abc")
                        if sortOrder == .titleAZ {
                            Image(systemName: "checkmark")
                        }
                    }
                    
                    Button(action: {
                        sortOrder = .createdNewest
                    }) {
                        Label("Date Created", systemImage: "calendar.badge.plus")
                        if sortOrder == .createdNewest {
                            Image(systemName: "checkmark")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .padding(.trailing)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Notes List
            if filteredNotes.isEmpty {
                EmptyNotesView(filter: filter)
            } else {
                List(selection: $notesViewModel.selectedNote) {
                    ForEach(filteredNotes) { note in
                        NoteRowView(note: note)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .contentShape(Rectangle()) // Ensure the entire row is tappable
                            .onTapGesture {
                                withAnimation {
                                    notesViewModel.selectedNote = note
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        notesViewModel.softDeleteNote(note)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                
                                Button {
                                    notesViewModel.pinNote(note)
                                } label: {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    // Share note
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                                
                                Menu {
                                    ForEach(notesViewModel.folders) { folder in
                                        Button {
                                            notesViewModel.moveNote(note, to: folder)
                                        } label: {
                                            Label(folder.name, systemImage: "folder")
                                        }
                                    }
                                    
                                    Button {
                                        notesViewModel.moveNote(note, to: nil)
                                    } label: {
                                        Label("None", systemImage: "tray")
                                    }
                                } label: {
                                    Label("Move", systemImage: "folder")
                                }
                                .tint(.purple)
                            }
                            .contextMenu {
                                Button(action: {
                                    notesViewModel.pinNote(note)
                                }) {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                                }
                                
                                Button(action: {
                                    // Share note
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                
                                Menu {
                                    ForEach(notesViewModel.folders) { folder in
                                        Button {
                                            notesViewModel.moveNote(note, to: folder)
                                        } label: {
                                            Label(folder.name, systemImage: "folder")
                                        }
                                    }
                                    
                                    Button {
                                        notesViewModel.moveNote(note, to: nil)
                                    } label: {
                                        Label("None", systemImage: "tray")
                                    }
                                } label: {
                                    Label("Move to Folder", systemImage: "folder")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    notesViewModel.softDeleteNote(note)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(navigationTitle)
        .onAppear {
            prepareHaptics()
            withAnimation(.easeOut(duration: 0.4)) {
                appearAnimation = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Create note in the current context based on filter
                    switch filter {
                    case .folder(let folder):
                        // Create note directly in the selected folder
                        notesViewModel.createNote(in: folder)
                        HapticFeedback.success() // Provide feedback
                    case .all, .tag, .pinned, .recent:
                        // Create note at root level for other views
                        notesViewModel.createNote()
                        HapticFeedback.light()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .alert("Error", isPresented: $showingErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
    
    private var filteredNotes: [Note] {
        // Get notes based on the filter
        var notes = notesViewModel.filteredNotes(for: filter)
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.contentBlocks.contains { block in
                    block.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .updatedNewest:
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        case .titleAZ:
            return notes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .createdNewest:
            return notes.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    /// Returns the appropriate navigation title based on the current filter
    private var navigationTitle: String {
        switch filter {
        case .all:
            return "All Notes"
        case .folder(let folder):
            return folder.name
        case .tag(let tag):
            return "#\(tag.name)"
        case .recent:
            return "Recently Deleted"
        case .pinned:
            return "Pinned Notes"
        }
    }
    
    /// Prepares the haptic engine for feedback
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }
}

struct NoteRowView: View {
    let note: Note
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    Text(note.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(formatDate(note.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !note.contentBlocks.isEmpty {
                        Text(previewText(from: note))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Tags
                if !note.tagIds.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tagIds, id: \.self) { tagId in
                                if let tag = notesViewModel.tags.first(where: { $0.id == tagId }) {
                                    TagPill(tag: tag)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Preview icon based on content type
            if let firstBlock = note.contentBlocks.first {
                contentTypeIcon(for: firstBlock.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func contentTypeIcon(for blockType: BlockType) -> some View {
        switch blockType {
        case .text:
            Image(systemName: "doc.text")
        case .image:
            Image(systemName: "photo")
        case .pdfEmbed:
            Image(systemName: "doc.fill")
        case .transcript:
            Image(systemName: "play.rectangle")
        case .ocrText:
            Image(systemName: "doc.text.viewfinder")
        case .aiGenerated:
            Image(systemName: "sparkles")
        case .markdown:
            Image(systemName: "text.badge.checkmark")
        case .youtube:
            Image(systemName: "play.rectangle")
        case .code:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
        case .link:
            Image(systemName: "link")
        case .audio:
            Image(systemName: "waveform")
        case .video:
            Image(systemName: "video")
        case .pdf:
            Image(systemName: "doc.fill")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func previewText(from note: Note) -> String {
        if let firstTextBlock = note.contentBlocks.first(where: { $0.type == .text || $0.type == .markdown }) {
            return firstTextBlock.content.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !note.contentBlocks.isEmpty {
            return "\(note.contentBlocks.count) items"
        }
        return "Empty note"
    }
}

struct TagPill: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.fromHex(tag.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(Color.fromHex(tag.colorHex)?.opacity(0.5) ?? Color.blue.opacity(0.5), lineWidth: 1)
                    )
            )
            .foregroundColor(Color.fromHex(tag.colorHex) ?? .blue)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search notes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

enum NoteSortOrder {
    case updatedNewest
    case titleAZ
    case createdNewest
}

struct EmptyNotesView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    var filter: NoteFilter = .all
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the + button to create your first AI-powered note")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                // Create note in the current context based on filter
                switch filter {
                case .folder(let folder):
                    // Create note directly in the selected folder
                    notesViewModel.createNote(in: folder)
                    HapticFeedback.success() // Provide feedback
                case .all, .tag, .pinned, .recent:
                    // Create note at root level for other views
                    notesViewModel.createNote()
                    HapticFeedback.light()
                }
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Create New Note")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NotesListView()
        .environmentObject(NotesViewModel())
}