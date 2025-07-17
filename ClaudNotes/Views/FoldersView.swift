//
//  FoldersView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct FoldersView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var showingNewFolderSheet = false
    @State private var showingTagsView = false
    @State private var newFolderName = ""
    @State private var selectedFolder: Folder?
    @State private var showingNoteDetail = false
    @State private var animateItems = false
    @State private var expandedSections = Set<String>(["iCloud", "Folders", "Tags"])
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List(selection: $selectedFolder) {
            // MARK: - iCloud Section
            Section {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains("iCloud") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("iCloud")
                            } else {
                                expandedSections.remove("iCloud")
                            }
                        }
                    ),
                    content: {
                        VStack(spacing: 0) {
                            NavigationLink(destination: NotesListView(filter: .all)) {
                                HStack {
                                    Image(systemName: "tray.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                    
                                    Text("All Notes")
                                        .font(.system(size: 15, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(notesViewModel.notes.count)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // New Note button for root level
                            Button(action: {
                                withAnimation {
                                    notesViewModel.createNote()
                                    notesViewModel.selectedNote = nil
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.linearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.purple.opacity(0.1))
                                        )
                                    
                                    Text("New Note")
                                        .font(.system(size: 15))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: NotesListView(filter: .recent)) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.linearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.red.opacity(0.1))
                                        )
                                    
                                    Text("Recently Deleted")
                                        .font(.system(size: 15, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(notesViewModel.recentlyDeletedNotes.count)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    },
                    label: {
                        HStack {
                            Image(systemName: "icloud")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            Text("iCloud")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                )
                .accentColor(.primary)
            }
            
            // MARK: - Folders Section
            Section {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains("Folders") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Folders")
                            } else {
                                expandedSections.remove("Folders")
                            }
                        }
                    ),
                    content: {
                        if notesViewModel.folders.isEmpty {
                            Text("No folders yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(notesViewModel.folders) { folder in
                                VStack(spacing: 0) {
                                    NavigationLink(destination: NotesListView(filter: .folder(folder))) {
                                        HStack {
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(.linearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 28, height: 28)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.yellow.opacity(0.1))
                                                )
                                            
                                            Text(folder.name)
                                                .font(.system(size: 15, weight: .medium))
                                            
                                            Spacer()
                                            
                                            Text("\(notesViewModel.notes.filter { $0.folderId == folder.id }.count)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.secondary.opacity(0.1))
                                                )
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            notesViewModel.deleteFolder(folder)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    
                                    // New Note button for this specific folder
                                    Button(action: {
                                        withAnimation {
                                            notesViewModel.createNote(in: folder)
                                            notesViewModel.selectedNote = nil
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12))
                                                .foregroundColor(.purple)
                                                .frame(width: 20, height: 20)
                                                .background(
                                                    Circle()
                                                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                                )
                                            
                                            Text("New in \(folder.name)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.leading, 36)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .onDelete(perform: deleteFolders)
                        }
                        
                        Button(action: {
                            showingNewFolderSheet = true
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                
                                Text("New Folder")
                                    .font(.system(size: 15))
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    },
                    label: {
                        HStack {
                            Image(systemName: "folder")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.linearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            Text("Folders")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                )
                .accentColor(.primary)
            }
            
            // MARK: - Tags Section
            Section {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains("Tags") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Tags")
                            } else {
                                expandedSections.remove("Tags")
                            }
                        }
                    ),
                    content: {
                        if notesViewModel.tags.isEmpty {
                            Text("No tags yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(notesViewModel.tags) { tag in
                                NavigationLink(destination: NotesListView(filter: .tag(tag))) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(tag.color.opacity(0.1))
                                                .frame(width: 28, height: 28)
                                            
                                            Image(systemName: "number")
                                                .font(.system(size: 12))
                                                .foregroundColor(tag.color)
                                        }
                                        
                                        Text(tag.name)
                                            .font(.system(size: 15, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Text("\(notesViewModel.notes.filter { $0.tagIds.contains(tag.id) }.count)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.secondary.opacity(0.1))
                                            )
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        notesViewModel.deleteTag(tag)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete(perform: deleteTags)
                        }
                        
                        Button(action: {
                            showingTagsView = true
                        }) {
                            HStack {
                                Image(systemName: "tag")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.linearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.green.opacity(0.1))
                                    )
                                
                                Text("Manage Tags")
                                    .font(.system(size: 15))
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    },
                    label: {
                        HStack {
                            Image(systemName: "tag")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.linearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            Text("Tags")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                )
                .accentColor(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            ZStack {
                Color(colorScheme == .dark ? .black : .systemGroupedBackground)
                    .opacity(0.95)
                
                // Subtle gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Folders")
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                animateItems = true
            }
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderView(isPresented: $showingNewFolderSheet)
        }
        .sheet(isPresented: $showingTagsView) {
            TagsView()
        }
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            let folder = notesViewModel.folders[index]
            notesViewModel.deleteFolder(folder)
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = notesViewModel.tags[index]
            notesViewModel.deleteTag(tag)
        }
    }
}

struct NewFolderView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @Binding var isPresented: Bool
    @State private var folderName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Folder Name", text: $folderName)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !folderName.isEmpty {
                            notesViewModel.createFolder(name: folderName)
                            isPresented = false
                        }
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        FoldersView()
            .environmentObject(NotesViewModel())
    }
}