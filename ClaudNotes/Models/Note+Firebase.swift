//
//  Note+Firebase.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Firebase Extensions for Note Model

extension Note {
    /// Convert Note to Firebase-compatible dictionary
    func toFirebaseData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "userId": userId,
            "title": title,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isPinned": isPinned,
            "isDeleted": isDeleted,
            "tagIds": tagIds.map { $0.uuidString }
        ]
        
        // Add optional fields
        if let folderId = folderId {
            data["folderId"] = folderId.uuidString
        }
        
        if let deletedAt = deletedAt {
            data["deletedAt"] = Timestamp(date: deletedAt)
        }
        
        // Convert content blocks
        data["contentBlocks"] = contentBlocks.map { $0.toFirebaseData() }
        
        return data
    }
    
    /// Create Note from Firebase document data
    static func fromFirebaseData(_ data: [String: Any]) throws -> Note {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw FirebaseError.invalidData
        }
        
        let isPinned = data["isPinned"] as? Bool ?? false
        let isDeleted = data["isDeleted"] as? Bool ?? false
        
        // Parse optional fields
        var folderId: UUID?
        if let folderIdString = data["folderId"] as? String {
            folderId = UUID(uuidString: folderIdString)
        }
        
        var deletedAt: Date?
        if let deletedAtTimestamp = data["deletedAt"] as? Timestamp {
            deletedAt = deletedAtTimestamp.dateValue()
        }
        
        // Parse tag IDs
        let tagIds = (data["tagIds"] as? [String] ?? []).compactMap { UUID(uuidString: $0) }
        
        // Parse content blocks
        let contentBlocksData = data["contentBlocks"] as? [[String: Any]] ?? []
        let contentBlocks = try contentBlocksData.map { try Block.fromFirebaseData($0) }
        
        return Note(
            id: id,
            userId: userId,
            title: title,
            contentBlocks: contentBlocks,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            folderId: folderId,
            tagIds: tagIds,
            isPinned: isPinned,
            isDeleted: isDeleted,
            deletedAt: deletedAt
        )
    }
    
    /// Get Firebase document ID (using UUID string)
    var firebaseId: String {
        return id.uuidString
    }
    
    /// Create a copy with updated timestamp
    func withUpdatedTimestamp() -> Note {
        var updatedNote = self
        updatedNote.updatedAt = Date()
        return updatedNote
    }
}

// MARK: - Firebase Extensions for Block Model

extension Block {
    /// Convert Block to Firebase-compatible dictionary
    func toFirebaseData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "type": type.rawValue,
            "content": content,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        // Add metadata if present
        if let metadata = metadata {
            data["metadata"] = metadata.toFirebaseData()
        }
        
        return data
    }
    
    /// Create Block from Firebase document data
    static func fromFirebaseData(_ data: [String: Any]) throws -> Block {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let typeString = data["type"] as? String,
              let type = BlockType(rawValue: typeString),
              let content = data["content"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw FirebaseError.invalidData
        }
        
        // Parse metadata if present
        var metadata: BlockMetadata?
        if let metadataData = data["metadata"] as? [String: Any] {
            metadata = try BlockMetadata.fromFirebaseData(metadataData)
        }
        
        // Create a new Block with the parsed data
        // Note: We'll need to create a custom initializer for Block to handle Firebase data
        return Block(
            id: id,
            type: type,
            content: content,
            metadata: metadata,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
}

// MARK: - Firebase Extensions for BlockMetadata

extension BlockMetadata {
    /// Convert BlockMetadata to Firebase-compatible dictionary
    func toFirebaseData() -> [String: Any] {
        var data: [String: Any] = [:]
        
        if let imageURL = imageURL {
            data["imageURL"] = imageURL
        }
        
        if let pdfURL = pdfURL {
            data["pdfURL"] = pdfURL
        }
        
        if let pageNumber = pageNumber {
            data["pageNumber"] = pageNumber
        }
        
        if let ocrConfidence = ocrConfidence {
            data["ocrConfidence"] = ocrConfidence
        }
        
        if let originalFileName = originalFileName {
            data["originalFileName"] = originalFileName
        }
        
        if let mimeType = mimeType {
            data["mimeType"] = mimeType
        }
        
        return data
    }
    
    /// Create BlockMetadata from Firebase document data
    static func fromFirebaseData(_ data: [String: Any]) throws -> BlockMetadata {
        return BlockMetadata(
            imageURL: data["imageURL"] as? String,
            pdfURL: data["pdfURL"] as? String,
            pageNumber: data["pageNumber"] as? Int,
            ocrConfidence: data["ocrConfidence"] as? Double,
            originalFileName: data["originalFileName"] as? String,
            mimeType: data["mimeType"] as? String
        )
    }
}

// MARK: - Firebase Extensions for Folder Model

extension Folder {
    /// Convert Folder to Firebase-compatible dictionary
    func toFirebaseData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    /// Create Folder from Firebase document data
    static func fromFirebaseData(_ data: [String: Any]) throws -> Folder {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw FirebaseError.invalidData
        }
        
        return Folder(
            id: id,
            userId: userId,
            name: name,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    /// Get Firebase document ID (using UUID string)
    var firebaseId: String {
        return id.uuidString
    }
}

// MARK: - Firebase Extensions for Tag Model

extension Tag {
    /// Convert Tag to Firebase-compatible dictionary
    func toFirebaseData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "colorHex": colorHex,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    /// Create Tag from Firebase document data
    static func fromFirebaseData(_ data: [String: Any]) throws -> Tag {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let colorHex = data["colorHex"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw FirebaseError.invalidData
        }
        
        return Tag(
            id: id,
            userId: userId,
            name: name,
            colorHex: colorHex,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    /// Get Firebase document ID (using UUID string)
    var firebaseId: String {
        return id.uuidString
    }
}

// MARK: - Sync Status Model

struct SyncStatus: Codable {
    let itemId: String
    let itemType: SyncItemType
    let status: SyncState
    let lastSyncAt: Date
    let errorMessage: String?
    
    enum SyncItemType: String, Codable {
        case note = "note"
        case folder = "folder"
        case tag = "tag"
    }
    
    enum SyncState: String, Codable {
        case synced = "synced"
        case pending = "pending"
        case error = "error"
        case conflict = "conflict"
    }
}

// MARK: - Query Helpers

extension Note {
    /// Query notes by folder
    static func queryByFolder(_ folderId: UUID?) -> [String: Any] {
        if let folderId = folderId {
            return ["folderId": folderId.uuidString]
        } else {
            return ["folderId": NSNull()]
        }
    }
    
    /// Query notes by tag (Note: Use this with whereField("tagIds", arrayContains: value) in actual queries)
    static func queryByTag(_ tagId: UUID) -> String {
        return tagId.uuidString
    }
    
    /// Query non-deleted notes
    static var queryActiveNotes: [String: Any] {
        return ["isDeleted": false]
    }
    
    /// Query pinned notes
    static var queryPinnedNotes: [String: Any] {
        return ["isPinned": true, "isDeleted": false]
    }
    
    /// Query deleted notes
    static var queryDeletedNotes: [String: Any] {
        return ["isDeleted": true]
    }
}