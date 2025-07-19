//
//  StorageService.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit
import Combine

/// Service for managing file uploads and downloads with Firebase Storage
@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private let storage = Storage.storage()
    private var storageRef: StorageReference {
        storage.reference()
    }
    
    @Published var uploadProgress: [String: Double] = [:]
    @Published var isUploading = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - File Upload Operations
    
    /// Upload an image and return the download URL
    func uploadImage(_ image: UIImage, noteId: UUID, quality: CGFloat = 0.8) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.notAuthenticated
        }
        
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw StorageError.invalidImageData
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let imagePath = "users/\(userId)/notes/\(noteId.uuidString)/images/\(fileName)"
        let imageRef = storageRef.child(imagePath)
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            // Upload with progress tracking
            let uploadTask = imageRef.putData(imageData, metadata: createImageMetadata())
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self?.uploadProgress[imagePath] = percentComplete
                    }
                }
            }
            
            // Wait for upload completion
            _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await imageRef.downloadURL()
            
            // Clean up progress tracking
            uploadProgress.removeValue(forKey: imagePath)
            
            return downloadURL.absoluteString
        } catch {
            uploadProgress.removeValue(forKey: imagePath)
            self.error = error
            throw error
        }
    }
    
    /// Upload a PDF document and return the download URL
    func uploadPDF(_ pdfData: Data, noteId: UUID, fileName: String) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.notAuthenticated
        }
        
        let sanitizedFileName = sanitizeFileName(fileName)
        let pdfPath = "users/\(userId)/notes/\(noteId.uuidString)/documents/\(sanitizedFileName)"
        let pdfRef = storageRef.child(pdfPath)
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            // Upload with progress tracking
            let uploadTask = pdfRef.putData(pdfData, metadata: createPDFMetadata(fileName: sanitizedFileName))
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self?.uploadProgress[pdfPath] = percentComplete
                    }
                }
            }
            
            // Wait for upload completion
            _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await pdfRef.downloadURL()
            
            // Clean up progress tracking
            uploadProgress.removeValue(forKey: pdfPath)
            
            return downloadURL.absoluteString
        } catch {
            uploadProgress.removeValue(forKey: pdfPath)
            self.error = error
            throw error
        }
    }
    
    /// Upload any file and return the download URL
    func uploadFile(_ fileData: Data, noteId: UUID, fileName: String, mimeType: String) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.notAuthenticated
        }
        
        let sanitizedFileName = sanitizeFileName(fileName)
        let filePath = "users/\(userId)/notes/\(noteId.uuidString)/files/\(sanitizedFileName)"
        let fileRef = storageRef.child(filePath)
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = mimeType
            metadata.customMetadata = [
                "originalFileName": fileName,
                "uploadedAt": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Upload with progress tracking
            let uploadTask = fileRef.putData(fileData, metadata: metadata)
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self?.uploadProgress[filePath] = percentComplete
                    }
                }
            }
            
            // Wait for upload completion
            _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await fileRef.downloadURL()
            
            // Clean up progress tracking
            uploadProgress.removeValue(forKey: filePath)
            
            return downloadURL.absoluteString
        } catch {
            uploadProgress.removeValue(forKey: filePath)
            self.error = error
            throw error
        }
    }
    
    // MARK: - File Download Operations
    
    /// Download file data from URL
    func downloadFile(from url: String) async throws -> Data {
        guard let downloadURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        let fileRef = storage.reference(forURL: url)
        
        do {
            let data = try await fileRef.data(maxSize: 50 * 1024 * 1024) // 50MB max
            return data
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Download image from URL
    func downloadImage(from url: String) async throws -> UIImage {
        let imageData = try await downloadFile(from: url)
        
        guard let image = UIImage(data: imageData) else {
            throw StorageError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - File Management Operations
    
    /// Delete file from storage
    func deleteFile(at url: String) async throws {
        let fileRef = storage.reference(forURL: url)
        
        do {
            try await fileRef.delete()
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Delete all files for a note
    func deleteAllFilesForNote(_ noteId: UUID) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.notAuthenticated
        }
        
        let notePath = "users/\(userId)/notes/\(noteId.uuidString)"
        let noteRef = storageRef.child(notePath)
        
        do {
            // List all files in the note directory
            let listResult = try await noteRef.listAll()
            
            // Delete all files
            for item in listResult.items {
                try await item.delete()
            }
            
            // Recursively delete subdirectories
            for prefix in listResult.prefixes {
                try await deleteDirectory(prefix)
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Delete directory recursively
    private func deleteDirectory(_ directoryRef: StorageReference) async throws {
        let listResult = try await directoryRef.listAll()
        
        // Delete all files in directory
        for item in listResult.items {
            try await item.delete()
        }
        
        // Recursively delete subdirectories
        for prefix in listResult.prefixes {
            try await deleteDirectory(prefix)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Create metadata for image uploads
    private func createImageMetadata() -> StorageMetadata {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "type": "note_image"
        ]
        return metadata
    }
    
    /// Create metadata for PDF uploads
    private func createPDFMetadata(fileName: String) -> StorageMetadata {
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "originalFileName": fileName,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "type": "note_document"
        ]
        return metadata
    }
    
    /// Sanitize file name for storage
    private func sanitizeFileName(_ fileName: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        let sanitized = fileName.components(separatedBy: allowedCharacters.inverted).joined(separator: "_")
        
        // Ensure file has an extension
        if !sanitized.contains(".") {
            return "\(sanitized).file"
        }
        
        return sanitized
    }
    
    /// Get file size from URL
    func getFileSize(from url: String) async throws -> Int64 {
        let fileRef = storage.reference(forURL: url)
        let metadata = try await fileRef.getMetadata()
        return metadata.size
    }
    
    /// Get file metadata from URL
    func getFileMetadata(from url: String) async throws -> StorageMetadata {
        let fileRef = storage.reference(forURL: url)
        return try await fileRef.getMetadata()
    }
    
    /// Clear error
    func clearError() {
        error = nil
    }
    
    /// Cancel upload for specific path
    func cancelUpload(for path: String) {
        uploadProgress.removeValue(forKey: path)
    }
    
    /// Get upload progress for path
    func getUploadProgress(for path: String) -> Double {
        return uploadProgress[path] ?? 0.0
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case notAuthenticated
    case invalidImageData
    case invalidURL
    case fileTooLarge
    case unsupportedFileType
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidImageData:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid file URL"
        case .fileTooLarge:
            return "File is too large"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .uploadFailed:
            return "File upload failed"
        case .downloadFailed:
            return "File download failed"
        }
    }
}

// MARK: - File Type Extensions

extension StorageService {
    /// Check if file type is supported
    func isFileTypeSupported(_ mimeType: String) -> Bool {
        let supportedTypes = [
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "application/pdf",
            "text/plain", "text/markdown",
            "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "audio/mpeg", "audio/wav", "audio/m4a",
            "video/mp4", "video/quicktime"
        ]
        
        return supportedTypes.contains(mimeType)
    }
    
    /// Get maximum file size for type
    func getMaxFileSize(for mimeType: String) -> Int64 {
        if mimeType.hasPrefix("image/") {
            return 10 * 1024 * 1024 // 10MB for images
        } else if mimeType == "application/pdf" {
            return 50 * 1024 * 1024 // 50MB for PDFs
        } else if mimeType.hasPrefix("video/") {
            return 100 * 1024 * 1024 // 100MB for videos
        } else {
            return 25 * 1024 * 1024 // 25MB for other files
        }
    }
}