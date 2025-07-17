//
//  NoteCardView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct NoteCardView: View {
    let note: Note
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and pin indicator
            HStack {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Preview content
            VStack(alignment: .leading, spacing: 8) {
                if let previewContent = previewContent {
                    Text(previewContent)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Content type indicators
                HStack(spacing: 12) {
                    ForEach(contentTypeIndicators, id: \.self) { indicator in
                        Image(systemName: indicator)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            } else {
                Spacer()
                    .frame(height: 12)
            }
            
            // Footer with date and folder
            HStack {
                Text(formatDate(note.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let folderId = note.folderId, 
                   let folder = notesViewModel.folders.first(where: { $0.id == folderId }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundColor(.yellow.opacity(0.8))
                        
                        Text(folder.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .contextMenu {
            Button(action: {
                notesViewModel.pinNote(note)
            }) {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            
            Menu {
                ForEach(notesViewModel.folders) { folder in
                    Button(action: {
                        notesViewModel.moveNote(note, to: folder)
                    }) {
                        Label(folder.name, systemImage: "folder")
                    }
                }
                
                Button(action: {
                    notesViewModel.moveNote(note, to: nil)
                }) {
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
    
    private var previewContent: String? {
        if let firstTextBlock = note.contentBlocks.first(where: { $0.type == .text || $0.type == .aiGenerated }) {
            return firstTextBlock.content
                .replacingOccurrences(of: "#.*?\n", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(100)
                .appending(note.contentBlocks.count > 1 ? "..." : "")
        } else if !note.contentBlocks.isEmpty {
            return "This note contains \(note.contentBlocks.count) items"
        }
        return "Empty note"
    }
    
    private var contentTypeIndicators: [String] {
        var indicators: [String] = []
        
        let blockTypes = Set(note.contentBlocks.map { $0.type })
        
        if blockTypes.contains(.image) {
            indicators.append("photo")
        }
        
        if blockTypes.contains(.aiGenerated) {
            indicators.append("sparkles")
        }
        
        if blockTypes.contains(.transcript) {
            indicators.append("play.rectangle")
        }
        
        if blockTypes.contains(.pdfEmbed) {
            indicators.append("doc.fill")
        }
        
        if blockTypes.contains(.ocrText) {
            indicators.append("doc.text.viewfinder")
        }
        
        return indicators
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let sampleNote = Note(title: "Sample Note", userId: "user1")
    return NoteCardView(note: sampleNote)
        .environmentObject(NotesViewModel())
        .padding()
        .background(Color.black)
}