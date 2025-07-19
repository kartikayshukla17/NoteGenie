//
//  Model.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import Foundation
import SwiftUI

// MARK: - Folder Models
struct Folder: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: String
    var name: String
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, userId: String) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID, userId: String, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tag Models
struct Tag: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: String
    var name: String
    var colorHex: String
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, userId: String, colorHex: String) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID, userId: String, name: String, colorHex: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var color: Color {
        Color.fromHex(colorHex) ?? .blue
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Note Models
struct Note: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: String
    var title: String
    var contentBlocks: [Block]
    let createdAt: Date
    var updatedAt: Date
    var folderId: UUID?
    var tagIds: [UUID]
    var isPinned: Bool
    var isDeleted: Bool
    var deletedAt: Date?
    
    init(title: String = "New Note", userId: String, folderId: UUID? = nil) {
        self.id = UUID()
        self.userId = userId
        self.title = title
        self.contentBlocks = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folderId = folderId
        self.tagIds = []
        self.isPinned = false
        self.isDeleted = false
        self.deletedAt = nil
    }
    
    init(id: UUID, userId: String, title: String, contentBlocks: [Block], createdAt: Date, updatedAt: Date, folderId: UUID? = nil, tagIds: [UUID] = [], isPinned: Bool = false, isDeleted: Bool = false, deletedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.contentBlocks = contentBlocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folderId = folderId
        self.tagIds = tagIds
        self.isPinned = isPinned
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Block Models
enum BlockType: String, Codable, CaseIterable, Sendable {
    case text = "text"
    case image = "image"
    case pdfEmbed = "pdf_embed"
    case pdf = "pdf"
    case transcript = "transcript"
    case ocrText = "ocr_text"
    case aiGenerated = "ai_generated"
    case markdown = "markdown"
    case youtube = "youtube"
    case code = "code"
    case link = "link"
    case audio = "audio"
    case video = "video"
}

struct Block: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var type: BlockType
    var content: String
    var metadata: BlockMetadata?
    let createdAt: Date
    var updatedAt: Date
    
    init(type: BlockType, content: String, metadata: BlockMetadata? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.metadata = metadata
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Firebase-compatible initializer
    init(id: UUID, type: BlockType, content: String, metadata: BlockMetadata? = nil, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.type = type
        self.content = content
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }
}

struct BlockMetadata: Codable, Hashable, Sendable {
    var imageURL: String?
    var pdfURL: String?
    var pageNumber: Int?
    var ocrConfidence: Double?
    var originalFileName: String?
    var mimeType: String?
}

// MARK: - Media Models
struct MediaFile: Codable, Identifiable, Sendable {
    let id: UUID
    let noteId: UUID
    let type: MediaType
    let url: String
    let fileName: String
    let mimeType: String
    let size: Int64
    let createdAt: Date
}

enum MediaType: String, Codable, CaseIterable, Sendable {
    case image = "image"
    case pdf = "pdf"
    case document = "document"
}

// MARK: - User Models
// Note: This is a legacy model. Use the User model from Models/User.swift instead
struct LegacyUser: Codable, Identifiable, Sendable {
    let id: String
    let email: String
    let createdAt: Date
    var lastLoginAt: Date?
}

// MARK: - OCR Models
struct OCRResult: Codable, Sendable {
    let text: String
    let confidence: Double
    let boundingBoxes: [TextBoundingBox]
}

struct TextBoundingBox: Codable, Sendable {
    let text: String
    let confidence: Double
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Transcript Models
struct TranscriptSegment: Codable, Sendable {
    let start: Double
    let end: Double
    let text: String
    let confidence: Double?
}

struct TranscriptResult: Codable, Sendable {
    let videoUrl: String
    let title: String?
    let duration: Double?
    let segments: [TranscriptSegment]
}

// MARK: - AI Generation Models
enum AIGenerationType: String, Codable, CaseIterable, Sendable {
    case summary = "Summary"
    case flashcards = "Flashcards"
    case quiz = "Quiz"
    case cornell = "Cornell Notes"
    case qa = "Q&A"
    case custom = "Custom"
}
