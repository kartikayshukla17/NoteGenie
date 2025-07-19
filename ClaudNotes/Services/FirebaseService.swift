//
//  FirebaseService.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Core Firebase service providing base functionality for all Firebase operations
@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    @Published var isConnected = false
    @Published var currentUserId: String?
    
    private init() {
        setupAuthListener()
        setupConnectionListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication State
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUserId = user?.uid
                print("🔥 Firebase Auth State Changed - User ID: \(user?.uid ?? "nil")")
            }
        }
    }
    
    private func setupConnectionListener() {
        // For Firestore, we'll monitor connection through network reachability
        // This is a simplified approach - in production you might want to use Network framework
        isConnected = true
    }
    
    // MARK: - User Collection Reference
    
    func userCollection() throws -> CollectionReference {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        return db.collection("users").document(userId).collection("data")
    }
    
    func userDocument() throws -> DocumentReference {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        return db.collection("users").document(userId)
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Create a new document
    func create<T: Codable>(_ item: T, in collection: String, with id: String? = nil) async throws -> String {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let collectionRef = db.collection("users").document(userId).collection(collection)
        
        let documentRef: DocumentReference
        if let id = id {
            documentRef = collectionRef.document(id)
        } else {
            documentRef = collectionRef.document()
        }
        
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(item)
        
        try await documentRef.setData(data)
        return documentRef.documentID
    }
    
    /// Read a single document
    func read<T: Codable>(_ type: T.Type, from collection: String, id: String) async throws -> T? {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(userId).collection(collection).document(id)
        
        let snapshot = try await documentRef.getDocument()
        guard snapshot.exists else { return nil }
        
        let decoder = Firestore.Decoder()
        return try decoder.decode(type, from: snapshot.data() ?? [:])
    }
    
    /// Read all documents from a collection
    func readAll<T: Codable>(_ type: T.Type, from collection: String, limit: Int? = nil) async throws -> [T] {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        var query: Query = db.collection("users").document(userId).collection(collection)
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        let decoder = Firestore.Decoder()
        
        return try snapshot.documents.compactMap { document in
            try decoder.decode(type, from: document.data())
        }
    }
    
    /// Update a document
    func update<T: Codable>(_ item: T, in collection: String, id: String) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(userId).collection(collection).document(id)
        
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(item)
        
        try await documentRef.setData(data, merge: true)
    }
    
    /// Update specific fields
    func updateFields(in collection: String, id: String, fields: [String: Any]) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(userId).collection(collection).document(id)
        
        try await documentRef.updateData(fields)
    }
    
    /// Delete a document
    func delete(from collection: String, id: String) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(userId).collection(collection).document(id)
        
        try await documentRef.delete()
    }
    
    /// Soft delete (mark as deleted)
    func softDelete(from collection: String, id: String) async throws {
        try await updateFields(in: collection, id: id, fields: [
            "isDeleted": true,
            "deletedAt": Timestamp()
        ])
    }
    
    // MARK: - Real-time Listeners
    
    /// Listen to a collection with real-time updates
    func listen<T: Codable>(
        to collection: String,
        type: T.Type,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration? {
        
        guard let userId = currentUserId else {
            completion(.failure(FirebaseError.notAuthenticated))
            return nil
        }
        
        let collectionRef = db.collection("users").document(userId).collection(collection)
        
        return collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                let decoder = Firestore.Decoder()
                let items = try documents.compactMap { document in
                    try decoder.decode(type, from: document.data())
                }
                completion(.success(items))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Listen to a single document
    func listenToDocument<T: Codable>(
        in collection: String,
        id: String,
        type: T.Type,
        completion: @escaping (Result<T?, Error>) -> Void
    ) -> ListenerRegistration? {
        
        guard let userId = currentUserId else {
            completion(.failure(FirebaseError.notAuthenticated))
            return nil
        }
        
        let documentRef = db.collection("users").document(userId).collection(collection).document(id)
        
        return documentRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data() else {
                completion(.success(nil))
                return
            }
            
            do {
                let decoder = Firestore.Decoder()
                let item = try decoder.decode(type, from: data)
                completion(.success(item))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch operations
    func performBatch(_ operations: (WriteBatch, String) throws -> Void) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let batch = db.batch()
        
        try operations(batch, userId)
        try await batch.commit()
    }
    
    // MARK: - Query Builder
    
    func query<T: Codable>(
        collection: String,
        type: T.Type,
        where field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        
        let query = db.collection("users").document(userId).collection(collection).whereField(field, isEqualTo: value)
        
        let snapshot = try await query.getDocuments()
        let decoder = Firestore.Decoder()
        
        return try snapshot.documents.compactMap { document in
            try decoder.decode(type, from: document.data())
        }
    }
}

// MARK: - Firebase Errors

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case invalidData
    case networkError
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}

// MARK: - Extensions

extension Firestore.Encoder {
    func encode<T: Codable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        return json as? [String: Any] ?? [:]
    }
}

extension Firestore.Decoder {
    func decode<T: Codable>(_ type: T.Type, from data: [String: Any]) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(type, from: jsonData)
    }
}