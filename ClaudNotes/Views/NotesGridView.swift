//
//  NotesGridView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct NotesGridView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    var filter: NoteFilter = .all
    @State private var gridLayout = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 16) {
                ForEach(notesViewModel.filteredNotes(for: filter)) { note in
                    NoteCardView(note: note)
                        .onTapGesture {
                            notesViewModel.selectedNote = note
                        }
                        .frame(minHeight: 180)
                }
            }
            .padding(16)
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        gridLayout = [GridItem(.adaptive(minimum: 160), spacing: 16)]
                    }) {
                        Label("Grid View", systemImage: "square.grid.2x2")
                    }
                    
                    Button(action: {
                        gridLayout = [GridItem(.flexible())]
                    }) {
                        Label("List View", systemImage: "list.bullet")
                    }
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch filter {
        case .all:
            return "All Notes"
        case .folder(let folder):
            return folder.name
        case .tag(let tag):
            return "Tag: \(tag.name)"
        case .recent:
            return "Recently Deleted"
        case .pinned:
            return "Pinned Notes"
        }
    }
}

#Preview {
    NavigationView {
        NotesGridView()
            .environmentObject(NotesViewModel())
    }
}