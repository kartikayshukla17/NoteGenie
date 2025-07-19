//
//  User.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import Foundation
import FirebaseAuth

/// User model representing an authenticated user
struct User: Identifiable, Codable, Equatable {
    let id: String
    let fullname: String
    let email: String
    var profileImageUrl: String?
    var provider: String? // "google" or "email"
    let createdAt: Date
    var lastLoginAt: Date
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
    
    // Custom initializer
    init(id: String, fullname: String, email: String, provider: String? = nil) {
        self.id = id
        self.fullname = fullname
        self.email = email
        self.provider = provider
        self.profileImageUrl = nil
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
    
    // Computed property to get display name (for backward compatibility)
    var displayName: String {
        return fullname.isEmpty ? email.components(separatedBy: "@").first ?? "User" : fullname
    }
    
    // Computed property to get avatar URL
    var avatarURL: URL? {
        if let profileImageUrl = profileImageUrl {
            return URL(string: profileImageUrl)
        }
        return nil
    }
    
    // Equatable implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

extension User {
    static var MOCK_USER = User(id: UUID().uuidString, fullname: "Tim Cook", email: "test@gmail.com")
    
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.fullname = firebaseUser.displayName ?? "User"
        self.email = firebaseUser.email ?? ""
        self.profileImageUrl = firebaseUser.photoURL?.absoluteString
        self.createdAt = Date()
        self.lastLoginAt = Date()
        
        // Determine provider
        if let providerData = firebaseUser.providerData.first {
            switch providerData.providerID {
            case "google.com":
                self.provider = "google"
            case "password":
                self.provider = "email"
            default:
                self.provider = providerData.providerID
            }
        } else {
            self.provider = "email"
        }
    }
}

/// User profile model for storing additional user information
struct UserProfile: Codable, Identifiable {
    let id: String
    var username: String?
    var avatarUrl: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}