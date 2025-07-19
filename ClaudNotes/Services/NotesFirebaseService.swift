//
//  NotesFirebaseService.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Service for managing Notes CRUD operations with Firebase
@MainActor
class NotesFirebaseService: ObservableObject {
    static let shared = NotesFirebaseService()
    
    private let firebaseService = FirebaseService.shared
    private let collectionName = "notes"
    private let foldersCollectionName = "folders"
    private let tagsCollectionName = "tags"
    
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var notesListener: ListenerRegistration?
    private var foldersListener: ListenerRegistration?
    private var tagsListener: ListenerRegistration?
    
    private init() {
        setupRealtimeListeners()
    }
    
    deinit {
        Task { @MainActor in
            removeListeners()
        }
    }
    
    // MARK: - Real-time Listeners
    
    private func setupRealtimeListeners() {
        print("🔥 NotesFirebaseService: Setting up real-time listeners")
        print("🔥 Current user ID: \(firebaseService.currentUserId ?? "nil")")
        
        // Only set up listeners if user is authenticated
        guard firebaseService.currentUserId != nil else {
            print("🔥 User not authenticated, skipping listener setup")
            return
        }
        
        setupNotesListener()
        setupFoldersListener()
        setupTagsListener()
    }
    
    private func setupNotesListener() {
        guard let userId = firebaseService.currentUserId else { return }
        
        let collectionRef = Firestore.firestore().collection("users").document(userId).collection(collectionName)
        
        notesListener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.notes = []
                    return
                }
                
                do {
                    let notes = try documents.compactMap { document in
                        try Note.fromFirebaseData(document.data())
                    }
                    self?.notes = notes.filter { !$0.isDeleted }.sorted { $0.updatedAt > $1.updatedAt }
                } catch {
                    self?.error = error
                }
            }
        }
    }
    
    private func setupFoldersListener() {
        guard let userId = firebaseService.currentUserId else { return }
        
        let collectionRef = Firestore.firestore().collection("users").document(userId).collection(foldersCollectionName)
        
        foldersListener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.folders = []
                    return
                }
                
                do {
                    let folders = try documents.compactMap { document in
                        try Folder.fromFirebaseData(document.data())
                    }
                    self?.folders = folders.sorted { $0.name < $1.name }
                } catch {
                    self?.error = error
                }
            }
        }
    }
    
    private func setupTagsListener() {
        guard let userId = firebaseService.currentUserId else { return }
        
        let collectionRef = Firestore.firestore().collection("users").document(userId).collection(tagsCollectionName)
        
        tagsListener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.tags = []
                    return
                }
                
                do {
                    let tags = try documents.compactMap { document in
                        try Tag.fromFirebaseData(document.data())
                    }
                    self?.tags = tags.sorted { $0.name < $1.name }
                } catch {
                    self?.error = error
                }
            }
        }
    }
    
    private func removeListeners() {
        notesListener?.remove()
        foldersListener?.remove()
        tagsListener?.remove()
    }
    
    // MARK: - Notes CRUD Operations
    
    /// Create a new note
    func createNote(_ note: Note) async throws -> String {
        print("🔥 NotesFirebaseService: Attempting to create note '\(note.title)'")
        print("🔥 Current user ID: \(firebaseService.currentUserId ?? "nil")")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                print("🔥 ERROR: User not authenticated")
                throw FirebaseError.notAuthenticated
            }
            
            let noteData = note.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(collectionName).document(note.firebaseId)
            
            print("🔥 Attempting to save note to path: users/\(userId)/\(collectionName)/\(note.firebaseId)")
            
            try await documentRef.setData(noteData)
            
            print("🔥 Successfully created note in Firebase: \(note.title)")
            return documentRef.documentID
        } catch {
            print("🔥 ERROR creating note: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }
    
    /// Create a new note with title and optional folder
    func createNote(title: String = "New Note", folderId: UUID? = nil) async throws -> Note {
        guard let userId = firebaseService.currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let note = Note(title: title, userId: userId, folderId: folderId)
        _ = try await createNote(note)
        return note
    }
    
    /// Update an existing note
    func updateNote(_ note: Note) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                throw FirebaseError.notAuthenticated
            }
            
            let updatedNote = note.withUpdatedTimestamp()
            let noteData = updatedNote.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(collectionName).document(note.firebaseId)
            
            try await documentRef.setData(noteData, merge: true)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Update note title
    func updateNoteTitle(_ noteId: UUID, title: String) async throws {
        try await firebaseService.updateFields(in: collectionName, id: noteId.uuidString, fields: [
            "title": title,
            "updatedAt": Timestamp()
        ])
    }
    
    /// Add content block to note
    func addContentBlock(to noteId: UUID, block: Block) async throws {
        if let noteIndex = notes.firstIndex(where: { $0.id == noteId }) {
            var note = notes[noteIndex]
            note.contentBlocks.append(block)
            try await updateNote(note)
        }
    }
    
    /// Update content block in note
    func updateContentBlock(in noteId: UUID, blockId: UUID, content: String) async throws {
        if let noteIndex = notes.firstIndex(where: { $0.id == noteId }),
           let blockIndex = notes[noteIndex].contentBlocks.firstIndex(where: { $0.id == blockId }) {
            var note = notes[noteIndex]
            note.contentBlocks[blockIndex].content = content
            note.contentBlocks[blockIndex].updatedAt = Date()
            try await updateNote(note)
        }
    }
    
    /// Remove content block from note
    func removeContentBlock(from noteId: UUID, blockId: UUID) async throws {
        if let noteIndex = notes.firstIndex(where: { $0.id == noteId }) {
            var note = notes[noteIndex]
            note.contentBlocks.removeAll { $0.id == blockId }
            try await updateNote(note)
        }
    }
    
    /// Pin/unpin a note
    func togglePinNote(_ noteId: UUID) async throws {
        if let note = notes.first(where: { $0.id == noteId }) {
            try await firebaseService.updateFields(in: collectionName, id: note.firebaseId, fields: [
                "isPinned": !note.isPinned,
                "updatedAt": Timestamp()
            ])
        }
    }
    
    /// Move note to folder
    func moveNote(_ noteId: UUID, to folderId: UUID?) async throws {
        let fields: [String: Any] = [
            "folderId": folderId?.uuidString ?? NSNull(),
            "updatedAt": Timestamp()
        ]
        
        try await firebaseService.updateFields(in: collectionName, id: noteId.uuidString, fields: fields)
    }
    
    /// Soft delete a note
    func softDeleteNote(_ noteId: UUID) async throws {
        try await firebaseService.updateFields(in: collectionName, id: noteId.uuidString, fields: [
            "isDeleted": true,
            "deletedAt": Timestamp(),
            "updatedAt": Timestamp()
        ])
    }
    
    /// Restore a deleted note
    func restoreNote(_ noteId: UUID) async throws {
        try await firebaseService.updateFields(in: collectionName, id: noteId.uuidString, fields: [
            "isDeleted": false,
            "deletedAt": NSNull(),
            "updatedAt": Timestamp()
        ])
    }
    
    /// Permanently delete a note
    func permanentlyDeleteNote(_ noteId: UUID) async throws {
        try await firebaseService.delete(from: collectionName, id: noteId.uuidString)
    }
    
    /// Get deleted notes
    func getDeletedNotes() async throws -> [Note] {
        guard let userId = firebaseService.currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let query = Firestore.firestore().collection("users").document(userId).collection(collectionName).whereField("isDeleted", isEqualTo: true)
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Note.fromFirebaseData(document.data())
        }
    }
    
    // MARK: - Folders CRUD Operations
    
    /// Create a new folder
    func createFolder(_ folder: Folder) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                throw FirebaseError.notAuthenticated
            }
            
            let folderData = folder.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(foldersCollectionName).document(folder.firebaseId)
            
            try await documentRef.setData(folderData)
            return documentRef.documentID
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Create a new folder with name
    func createFolder(name: String) async throws -> Folder {
        guard let userId = firebaseService.currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let folder = Folder(name: name, userId: userId)
        _ = try await createFolder(folder)
        return folder
    }
    
    /// Update folder
    func updateFolder(_ folder: Folder) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                throw FirebaseError.notAuthenticated
            }
            
            var updatedFolder = folder
            updatedFolder.updatedAt = Date()
            let folderData = updatedFolder.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(foldersCollectionName).document(folder.firebaseId)
            
            try await documentRef.setData(folderData, merge: true)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Delete folder and move notes to no folder
    func deleteFolder(_ folderId: UUID) async throws {
        // First, move all notes in this folder to no folder
        let notesInFolder = notes.filter { $0.folderId == folderId }
        
        try await firebaseService.performBatch { batch, userId in
            let db = Firestore.firestore()
            
            // Update all notes in the folder
            for note in notesInFolder {
                let noteRef = db.collection("users").document(userId).collection(self.collectionName).document(note.firebaseId)
                batch.updateData([
                    "folderId": NSNull(),
                    "updatedAt": Timestamp()
                ], forDocument: noteRef)
            }
            
            // Delete the folder
            let folderRef = db.collection("users").document(userId).collection(self.foldersCollectionName).document(folderId.uuidString)
            batch.deleteDocument(folderRef)
        }
    }
    
    // MARK: - Tags CRUD Operations
    
    /// Create a new tag
    func createTag(_ tag: Tag) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                throw FirebaseError.notAuthenticated
            }
            
            let tagData = tag.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(tagsCollectionName).document(tag.firebaseId)
            
            try await documentRef.setData(tagData)
            return documentRef.documentID
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Create a new tag with name and color
    func createTag(name: String, colorHex: String) async throws -> Tag {
        guard let userId = firebaseService.currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let tag = Tag(name: name, userId: userId, colorHex: colorHex)
        _ = try await createTag(tag)
        return tag
    }
    
    /// Update tag
    func updateTag(_ tag: Tag) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = firebaseService.currentUserId else {
                throw FirebaseError.notAuthenticated
            }
            
            var updatedTag = tag
            updatedTag.updatedAt = Date()
            let tagData = updatedTag.toFirebaseData()
            let documentRef = Firestore.firestore().collection("users").document(userId).collection(tagsCollectionName).document(tag.firebaseId)
            
            try await documentRef.setData(tagData, merge: true)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Delete tag and remove from all notes
    func deleteTag(_ tagId: UUID) async throws {
        // First, remove tag from all notes
        let notesWithTag = notes.filter { $0.tagIds.contains(tagId) }
        
        try await firebaseService.performBatch { batch, userId in
            // Update all notes with this tag
            for note in notesWithTag {
                let noteRef = Firestore.firestore().collection("users").document(userId).collection(self.collectionName).document(note.firebaseId)
                let updatedTagIds = note.tagIds.filter { $0 != tagId }.map { $0.uuidString }
                batch.updateData([
                    "tagIds": updatedTagIds,
                    "updatedAt": Timestamp()
                ], forDocument: noteRef)
            }
            
            // Delete the tag
            let tagRef = Firestore.firestore().collection("users").document(userId).collection(self.tagsCollectionName).document(tagId.uuidString)
            batch.deleteDocument(tagRef)
        }
    }
    
    /// Add tag to note
    func addTagToNote(_ noteId: UUID, tagId: UUID) async throws {
        if let note = notes.first(where: { $0.id == noteId }),
           !note.tagIds.contains(tagId) {
            var updatedTagIds = note.tagIds
            updatedTagIds.append(tagId)
            
            try await firebaseService.updateFields(in: collectionName, id: note.firebaseId, fields: [
                "tagIds": updatedTagIds.map { $0.uuidString },
                "updatedAt": Timestamp()
            ])
        }
    }
    
    /// Remove tag from note
    func removeTagFromNote(_ noteId: UUID, tagId: UUID) async throws {
        if let note = notes.first(where: { $0.id == noteId }),
           note.tagIds.contains(tagId) {
            let updatedTagIds = note.tagIds.filter { $0 != tagId }
            
            try await firebaseService.updateFields(in: collectionName, id: note.firebaseId, fields: [
                "tagIds": updatedTagIds.map { $0.uuidString },
                "updatedAt": Timestamp()
            ])
        }
    }
    
    // MARK: - Search and Filter Operations
    
    /// Search notes by title and content
    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return notes }
        
        let lowercaseQuery = query.lowercased()
        return notes.filter { note in
            note.title.lowercased().contains(lowercaseQuery) ||
            note.contentBlocks.contains { block in
                block.content.lowercased().contains(lowercaseQuery)
            }
        }
    }
    
    /// Get notes by folder
    func getNotes(in folderId: UUID?) -> [Note] {
        return notes.filter { $0.folderId == folderId }
    }
    
    /// Get notes by tag
    func getNotes(with tagId: UUID) -> [Note] {
        return notes.filter { $0.tagIds.contains(tagId) }
    }
    
    /// Get pinned notes
    func getPinnedNotes() -> [Note] {
        return notes.filter { $0.isPinned }
    }
    
    /// Get recent notes
    func getRecentNotes(limit: Int = 10) -> [Note] {
        return Array(notes.prefix(limit))
    }
    
    // MARK: - Batch Operations
    
    /// Delete multiple notes
    func deleteMultipleNotes(_ noteIds: [UUID]) async throws {
        try await firebaseService.performBatch { batch, userId in
            for noteId in noteIds {
                let noteRef = Firestore.firestore().collection("users").document(userId).collection(self.collectionName).document(noteId.uuidString)
                batch.updateData([
                    "isDeleted": true,
                    "deletedAt": Timestamp(),
                    "updatedAt": Timestamp()
                ], forDocument: noteRef)
            }
        }
    }
    
    /// Move multiple notes to folder
    func moveMultipleNotes(_ noteIds: [UUID], to folderId: UUID?) async throws {
        try await firebaseService.performBatch { batch, userId in
            for noteId in noteIds {
                let noteRef = Firestore.firestore().collection("users").document(userId).collection(self.collectionName).document(noteId.uuidString)
                batch.updateData([
                    "folderId": folderId?.uuidString ?? NSNull(),
                    "updatedAt": Timestamp()
                ], forDocument: noteRef)
            }
        }
    }
    
    /// Add tag to multiple notes
    func addTagToMultipleNotes(_ noteIds: [UUID], tagId: UUID) async throws {
        try await firebaseService.performBatch { batch, userId in
            for noteId in noteIds {
                if let note = self.notes.first(where: { $0.id == noteId }),
                   !note.tagIds.contains(tagId) {
                    var updatedTagIds = note.tagIds
                    updatedTagIds.append(tagId)
                    
                    let noteRef = Firestore.firestore().collection("users").document(userId).collection(self.collectionName).document(note.firebaseId)
                    batch.updateData([
                        "tagIds": updatedTagIds.map { $0.uuidString },
                        "updatedAt": Timestamp()
                    ], forDocument: noteRef)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Initialize Firebase listeners when user becomes authenticated
    func initializeForUser() {
        print("🔥 NotesFirebaseService: Initializing for authenticated user")
        removeListeners() // Remove any existing listeners
        setupRealtimeListeners() // Set up new listeners for the authenticated user
    }
    
    /// Clear error
    func clearError() {
        error = nil
    }
    
    /// Refresh data
    func refreshData() async {
        // The real-time listeners will automatically update the data
        // This method can be used to force a refresh if needed
        removeListeners()
        setupRealtimeListeners()
    }
}
