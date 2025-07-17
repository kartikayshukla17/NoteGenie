//
//  NotesViewModel.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import Combine
import OSLog

// Define custom error types following Swift's best practices
enum NotesError: Error, LocalizedError {
    case saveFailure
    case loadFailure
    case noteNotFound(id: UUID)
    case folderNotFound(id: UUID)
    case tagNotFound(id: UUID)
    case invalidOperation(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailure:
            return "Failed to save data"
        case .loadFailure:
            return "Failed to load data"
        case .noteNotFound(let id):
            return "Note not found: \(id)"
        case .folderNotFound(let id):
            return "Folder not found: \(id)"
        case .tagNotFound(let id):
            return "Tag not found: \(id)"
        case .invalidOperation(let reason):
            return "Invalid operation: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailure:
            return "Try again or restart the app"
        case .loadFailure:
            return "Check if the data exists or restart the app"
        case .noteNotFound, .folderNotFound, .tagNotFound:
            return "The item may have been deleted"
        case .invalidOperation:
            return "Try a different approach"
        }
    }
}

@MainActor
class NotesViewModel: ObservableObject {
    // Logger for structured logging
    private let logger = Logger(subsystem: "com.claudnotes.app", category: "NotesViewModel")
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var tags: [Tag] = []
    @Published var selectedNote: Note?
    @Published var selectedFolder: Folder?
    @Published var selectedTag: Tag?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var showingCreateNote = false
    
    private var cancellables = Set<AnyCancellable>()
    private let youtubeService = YouTubeService()
    private let geminiService = GeminiService()
    
    var recentlyDeletedNotes: [Note] {
        notes.filter { $0.isDeleted }
    }
    
    func filteredNotes(for filter: NoteFilter = .all) -> [Note] {
        let filteredByStatus: [Note]
        
        switch filter {
        case .all:
            filteredByStatus = notes.filter { !$0.isDeleted }
        case .folder(let folder):
            filteredByStatus = notes.filter { !$0.isDeleted && $0.folderId == folder.id }
        case .tag(let tag):
            filteredByStatus = notes.filter { !$0.isDeleted && $0.tagIds.contains(tag.id) }
        case .recent:
            filteredByStatus = notes.filter { $0.isDeleted }
        case .pinned:
            filteredByStatus = notes.filter { !$0.isDeleted && $0.isPinned }
        }
        
        if searchText.isEmpty {
            return filteredByStatus
        }
        
        return filteredByStatus.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.contentBlocks.contains { block in
                block.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    init() {
        loadNotes()
        loadFolders()
        loadTags()
        
        // Create sample content if there are no notes or folders
        if notes.isEmpty {
            createSampleContent()
        }
    }
    
    private func createSampleContent() {
        // Create sample folders
        let personalFolder = Folder(name: "Personal", userId: "default_user")
        let workFolder = Folder(name: "Work", userId: "default_user")
        let ideasFolder = Folder(name: "Ideas", userId: "default_user")
        
        folders = [personalFolder, workFolder, ideasFolder]
        saveFolders()
        
        // Create sample tags
        let workTag = Tag(name: "Work", userId: "default_user", colorHex: "#3B82F6") // Blue
        let personalTag = Tag(name: "Personal", userId: "default_user", colorHex: "#10B981") // Green
        let importantTag = Tag(name: "Important", userId: "default_user", colorHex: "#EF4444") // Red
        let ideasTag = Tag(name: "Ideas", userId: "default_user", colorHex: "#F59E0B") // Orange
        let projectsTag = Tag(name: "Projects", userId: "default_user", colorHex: "#8B5CF6") // Purple
        
        tags = [workTag, personalTag, importantTag, ideasTag, projectsTag]
        saveTags()
        
        // Create welcome note
        createSampleNote()
        
        // Create a note in the Personal folder with tags
        var personalNote = Note(title: "Personal Goals", userId: "default_user", folderId: personalFolder.id)
        personalNote.tagIds = [personalTag.id, ideasTag.id]
        let personalBlock = Block(
            type: .text,
            content: "# My Personal Goals\n\n- Exercise 3 times a week\n- Read one book per month\n- Learn to play the guitar\n- Practice meditation daily\n- Cook a new recipe every weekend"
        )
        var personalNoteWithBlock = personalNote
        personalNoteWithBlock.contentBlocks.append(personalBlock)
        notes.append(personalNoteWithBlock)
        
        // Create a note in the Work folder with tags
        var workNote = Note(title: "Project Ideas", userId: "default_user", folderId: workFolder.id)
        workNote.tagIds = [workTag.id, ideasTag.id, projectsTag.id]
        let workBlock = Block(
            type: .text,
            content: "# Project Ideas\n\n1. Mobile app for task management\n2. AI-powered content generator\n3. Smart home automation system\n4. Health tracking platform\n5. Educational platform for coding"
        )
        var workNoteWithBlock = workNote
        workNoteWithBlock.contentBlocks.append(workBlock)
        notes.append(workNoteWithBlock)
        
        // Create a pinned note with tags
        var pinnedNote = Note(title: "Important Contacts", userId: "default_user")
        pinnedNote.isPinned = true
        pinnedNote.tagIds = [importantTag.id, workTag.id]
        let pinnedBlock = Block(
            type: .text,
            content: "# Important Contacts\n\n- Tech Support: (555) 123-4567\n- Office Manager: [email@example.com](mailto:email@example.com)\n- Team Lead: John Smith\n- HR Department: ext. 5432"
        )
        var pinnedNoteWithBlock = pinnedNote
        pinnedNoteWithBlock.contentBlocks.append(pinnedBlock)
        notes.append(pinnedNoteWithBlock)
        
        // Create an AI-generated note
        var aiNote = Note(title: "AI-Generated Summary", userId: "default_user", folderId: ideasFolder.id)
        aiNote.tagIds = [projectsTag.id]
        let aiBlock = Block(
            type: .aiGenerated,
            content: "# Meeting Summary\n\n## Key Points\n\n- Project timeline extended by 2 weeks\n- Budget approved for new design tools\n- Marketing team to prepare launch materials by next Friday\n- User testing scheduled for the last week of the month\n\n## Action Items\n\n- John: Update project timeline in management system\n- Sarah: Coordinate with marketing on launch materials\n- Michael: Prepare user testing scenarios\n- Everyone: Review updated requirements document by Wednesday"
        )
        var aiNoteWithBlock = aiNote
        aiNoteWithBlock.contentBlocks.append(aiBlock)
        notes.append(aiNoteWithBlock)
        
        // Create a YouTube transcript note
        var youtubeNote = Note(title: "How to Build a SwiftUI App", userId: "default_user")
        youtubeNote.tagIds = [projectsTag.id, ideasTag.id]
        let youtubeBlock = Block(
            type: .transcript,
            content: "# How to Build a SwiftUI App\n\nIn this tutorial, we'll cover the basics of building a SwiftUI app from scratch. We'll start with the project setup, then move on to creating views, managing state, and finally deploying to the App Store.\n\n## Topics Covered\n\n- SwiftUI basics\n- State management\n- Navigation\n- Data persistence\n- Deployment",
            metadata: BlockMetadata(imageURL: "https://www.youtube.com/watch?v=example", originalFileName: "How to Build a SwiftUI App")
        )
        var youtubeNoteWithBlock = youtubeNote
        youtubeNoteWithBlock.contentBlocks.append(youtubeBlock)
        notes.append(youtubeNoteWithBlock)
        
        saveNotes()
    }
    
    func createNote(in folder: Folder? = nil) {
        let folderId = folder?.id ?? selectedFolder?.id
        let newNote = Note(title: "Untitled Note", userId: "default_user", folderId: folderId)
        notes.insert(newNote, at: 0) // Add to beginning of list like Apple Notes
        selectedNote = newNote
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            selectedNote = updatedNote
            
            // Move updated note to top of list like Apple Notes
            if index > 0 {
                notes.remove(at: index)
                notes.insert(updatedNote, at: 0)
            }
            
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
        saveNotes()
    }
    
    func addBlock(to note: Note, type: BlockType, content: String, metadata: BlockMetadata? = nil) {
        let newBlock = Block(type: type, content: content, metadata: metadata)
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.contentBlocks.append(newBlock)
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            selectedNote = updatedNote
            
            // Move updated note to top of list like Apple Notes
            if index > 0 {
                notes.remove(at: index)
                notes.insert(updatedNote, at: 0)
            }
            
            saveNotes()
        }
    }
    
    private func loadNotes() {
        do {
            guard let data = UserDefaults.standard.data(forKey: AppConstants.Keys.savedNotes) else {
                logger.info("No saved notes found, starting with empty collection")
                return
            }
            
            let decodedNotes = try JSONDecoder().decode([Note].self, from: data)
            self.notes = decodedNotes
            logger.debug("Successfully loaded \(decodedNotes.count) notes")
        } catch {
            logger.error("Failed to load notes: \(error.localizedDescription)")
            // In a production app, we might want to show an error to the user
            // or attempt to recover corrupted data
        }
    }
    
    private func saveNotes() {
        do {
            let encoded = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(encoded, forKey: AppConstants.Keys.savedNotes)
            logger.debug("Notes saved successfully")
        } catch {
            logger.error("Failed to save notes: \(error.localizedDescription)")
            // In a real app, we might want to show an alert to the user
            // or retry the operation
        }
    }
    
    // MARK: - YouTube Integration
    func createNoteFromYouTube(url: String) async {
        isLoading = true
        
        do {
            // Validate URL format
            guard URL(string: url) != nil else {
                throw NotesError.invalidOperation(reason: "Invalid YouTube URL format")
            }
            
            logger.debug("Fetching YouTube video info for URL: \(url)")
            let videoInfo = try await youtubeService.getVideoInfo(from: url)
            logger.info("Successfully retrieved YouTube video: \(videoInfo.title)")
            
            // Create new note with video title
            let newNote = Note(title: videoInfo.title, userId: "default_user")
            
            // Add video info block
            let videoBlock = Block(
                type: .transcript,
                content: "YouTube Video: \(videoInfo.title)\n\nDuration: \(formatDuration(videoInfo.duration))\n\nDescription: \(videoInfo.description)",
                metadata: BlockMetadata(imageURL: url, originalFileName: videoInfo.title)
            )
            
            var noteWithBlock = newNote
            noteWithBlock.contentBlocks.append(videoBlock)
            
            notes.insert(noteWithBlock, at: 0) // Add to beginning of list like Apple Notes
            selectedNote = noteWithBlock
            saveNotes()
            
        } catch let error as NotesError {
            logger.error("YouTube processing error: \(error.localizedDescription)")
            createErrorNote(title: "YouTube Error", message: "\(error.localizedDescription)\n\nURL: \(url)")
        } catch {
            logger.error("YouTube API error: \(error.localizedDescription)")
            createErrorNote(title: "YouTube Video", message: "Failed to fetch video information: \(error.localizedDescription)\n\nURL: \(url)")
        }
        
        isLoading = false
    }
    
    /// Creates a note with an error message
    private func createErrorNote(title: String, message: String) {
        let errorNote = Note(title: title, userId: "default_user")
        let errorBlock = Block(
            type: .text,
            content: message
        )
        var noteWithError = errorNote
        noteWithError.contentBlocks.append(errorBlock)
        notes.insert(noteWithError, at: 0)
        selectedNote = noteWithError
        saveNotes()
    }
    
    private func createSampleNote() {
        let welcomeNote = Note(title: "Welcome to ClaudNotes", userId: "default_user")
        
        let welcomeBlock = Block(
            type: .text,
            content: "Welcome to ClaudNotes! This app combines the simplicity of Apple Notes with powerful AI features.\n\nHere's what you can do:\n\n• Create and edit notes\n• Extract YouTube video transcripts\n• Generate AI-powered content\n• Export and share your notes"
        )
        
        let aiBlock = Block(
            type: .aiGenerated,
            content: "Try the AI features by tapping the sparkles icon in the toolbar. You can generate:\n\n• Summaries\n• Flashcards\n• Quizzes\n• Cornell Notes\n• Q&A pairs"
        )
        
        var noteWithBlocks = welcomeNote
        noteWithBlocks.contentBlocks.append(welcomeBlock)
        noteWithBlocks.contentBlocks.append(aiBlock)
        
        notes.append(noteWithBlocks)
        saveNotes()
    }
    
    // MARK: - AI Generation
    func generateAIContent(for note: Note, type: ClaudNotes.AIGenerationType) async {
        isLoading = true
        
        let existingContent = note.contentBlocks.map { $0.content }.joined(separator: "\n\n")
        
        guard !existingContent.isEmpty else {
            isLoading = false
            return
        }
        
        do {
            let generatedContent: String
            
            switch type {
            case .summary:
                generatedContent = try await geminiService.generateSummary(from: existingContent)
            case .flashcards:
                generatedContent = try await geminiService.generateFlashcards(from: existingContent)
            case .quiz:
                generatedContent = try await geminiService.generateQuiz(from: existingContent)
            case .cornell:
                generatedContent = try await geminiService.generateCornellNotes(from: existingContent)
            case .qa:
                generatedContent = try await geminiService.generateQA(from: existingContent)
            case .custom:
                generatedContent = try await geminiService.generateSummary(from: existingContent) // Default to summary
            }
            
            // Add AI-generated block to note
            addBlock(to: note, type: .aiGenerated, content: generatedContent)
            
        } catch {
            print("AI generation error: \(error)")
            // Add error block
            addBlock(to: note, type: .text, content: "AI generation failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Folder Management
    func createFolder(name: String) {
        let newFolder = Folder(name: name, userId: "default_user")
        folders.append(newFolder)
        saveFolders()
    }
    
    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            var updatedFolder = folder
            updatedFolder.updatedAt = Date()
            folders[index] = updatedFolder
            saveFolders()
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        // Move notes from this folder to the root level
        for i in 0..<notes.count {
            if notes[i].folderId == folder.id {
                notes[i].folderId = nil
            }
        }
        
        folders.removeAll { $0.id == folder.id }
        if selectedFolder?.id == folder.id {
            selectedFolder = nil
        }
        
        saveFolders()
        saveNotes()
    }
    
    func moveNote(_ note: Note, to folder: Folder?) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.folderId = folder?.id
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            saveNotes()
        }
    }
    
    func pinNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.isPinned.toggle()
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            saveNotes()
        }
    }
    
    func softDeleteNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.isDeleted = true
            updatedNote.deletedAt = Date()
            notes[index] = updatedNote
            
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
            
            saveNotes()
        }
    }
    
    func restoreNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.isDeleted = false
            updatedNote.deletedAt = nil
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func permanentlyDeleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
        saveNotes()
    }
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: AppConstants.Keys.savedFolders),
           let decodedFolders = try? JSONDecoder().decode([Folder].self, from: data) {
            self.folders = decodedFolders
        }
    }
    
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: AppConstants.Keys.savedFolders)
        }
    }
    
    // MARK: - Tag Management
    func createTag(name: String, color: Color) {
        let newTag = Tag(name: name, userId: "default_user", colorHex: color.toHex())
        tags.append(newTag)
        saveTags()
    }
    
    func updateTag(_ tag: Tag, name: String? = nil, color: Color? = nil) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            var updatedTag = tag
            
            if let name = name {
                updatedTag.name = name
            }
            
            if let color = color {
                updatedTag.colorHex = color.toHex()
            }
            
            updatedTag.updatedAt = Date()
            tags[index] = updatedTag
            saveTags()
        }
    }
    
    func deleteTag(_ tag: Tag) {
        // Remove tag from all notes
        for i in 0..<notes.count {
            notes[i].tagIds.removeAll { $0 == tag.id }
        }
        
        tags.removeAll { $0.id == tag.id }
        if selectedTag?.id == tag.id {
            selectedTag = nil
        }
        
        saveTags()
        saveNotes()
    }
    
    func addTagToNote(_ note: Note, tag: Tag) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            if !updatedNote.tagIds.contains(tag.id) {
                updatedNote.tagIds.append(tag.id)
                updatedNote.updatedAt = Date()
                notes[index] = updatedNote
                
                if selectedNote?.id == note.id {
                    selectedNote = updatedNote
                }
                
                saveNotes()
            }
        }
    }
    
    func removeTagFromNote(_ note: Note, tag: Tag) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = notes[index]
            updatedNote.tagIds.removeAll { $0 == tag.id }
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            saveNotes()
        }
    }
    
    private func loadTags() {
        if let data = UserDefaults.standard.data(forKey: AppConstants.Keys.savedTags),
           let decodedTags = try? JSONDecoder().decode([Tag].self, from: data) {
            self.tags = decodedTags
        }
    }
    
    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(encoded, forKey: AppConstants.Keys.savedTags)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
