//
//  User.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import Foundation

/// User model representing an authenticated user
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let createdAt: Date
    var userMetadata: [String: String]?
    var appMetadata: [String: String]?
    
    // Custom initializer for testing or manual creation
    init(id: String, email: String?, createdAt: Date, userMetadata: [String: String]? = nil, appMetadata: [String: String]? = nil) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.userMetadata = userMetadata
        self.appMetadata = appMetadata
    }
    
    // Computed property to get display name
    var displayName: String {
        if let name = userMetadata?["full_name"] {
            return name
        } else if let email = email {
            return email.components(separatedBy: "@").first ?? email
        } else {
            return "User"
        }
    }
    
    // Computed property to get avatar URL
    var avatarURL: URL? {
        if let avatarURLString = userMetadata?["avatar_url"] {
            return URL(string: avatarURLString)
        }
        return nil
    }
    
    // Equatable implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
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