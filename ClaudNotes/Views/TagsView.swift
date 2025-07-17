//
//  TagsView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct TagsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var newTagName = ""
    @State private var showingAddTag = false
    
    var body: some View {
        List {
            Section(header: Text("Tags")) {
                ForEach(notesViewModel.tags) { tag in
                    NavigationLink(destination: NotesListView(filter: .tag(tag))) {
                        HStack {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 12, height: 12)
                            
                            Text(tag.name)
                            
                            Spacer()
                            
                            Text("\(notesViewModel.notes.filter { $0.tagIds.contains(tag.id) && !$0.isDeleted }.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            // Edit tag
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            notesViewModel.deleteTag(tag)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteTags)
                
                Button(action: {
                    showingAddTag = true
                }) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("New Tag")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tags")
        .sheet(isPresented: $showingAddTag) {
            TagEditorView(isPresented: $showingAddTag)
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = notesViewModel.tags[index]
            notesViewModel.deleteTag(tag)
        }
    }
}

struct TagEditorView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @Binding var isPresented: Bool
    @State private var tagName = ""
    @State private var selectedColor: Color = .blue
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tag Details")) {
                    TextField("Tag Name", text: $tagName)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text("Color")
                        
                        Spacer()
                        
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(color == selectedColor ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                                .padding(.horizontal, 2)
                        }
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !tagName.isEmpty {
                            notesViewModel.createTag(name: tagName, color: selectedColor)
                            isPresented = false
                        }
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TagsView()
            .environmentObject(NotesViewModel())
    }
}