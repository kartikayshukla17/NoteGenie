//
//  Constants.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//
import Foundation

struct AppConstants {
    // MARK: - API Configuration
    struct API {
        static let youtubeBaseURL = "https://www.googleapis.com/youtube/v3"
        static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
        static let localServiceURL = "http://localhost:8000"
    }
    
    // MARK: - UserDefaults Keys
    struct Keys {
        static let savedNotes = "saved_notes"
        static let savedFolders = "saved_folders"
        static let savedTags = "saved_tags"
        static let recentlyDeletedNotes = "recently_deleted_notes"
        static let geminiAPIKey = "gemini_api_key"
        static let youtubeAPIKey = "youtube_api_key"
        static let userPreferences = "user_preferences"
        static let lastSyncTimestamp = "last_sync_timestamp"
    }
    
    // MARK: - UI Constants
    static let cornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 12
    static let glassOpacity: Double = 0.8
    static let shadowRadius: CGFloat = 20
    static let defaultPadding: CGFloat = 16
    
    // MARK: - Limits
    static let maxNoteTitle = 100
    static let maxBlockContent = 10000
    static let maxNotesPerUser = 1000
    static let maxFileSize = 10 * 1024 * 1024 // 10MB
    
    // MARK: - File Types
    static let supportedImageTypes = ["jpg", "jpeg", "png", "heic", "webp"]
    static let supportedDocumentTypes = ["pdf", "txt", "rtf", "doc", "docx"]
}

// VioletTheme.swift
import SwiftUI

struct VioletTheme {
    // Primary Violet Palette
    static let primary = Color(red: 0.55, green: 0.27, blue: 0.94) // #8B44F0
    static let secondary = Color(red: 0.75, green: 0.48, blue: 0.98) // #BF7AF8
    static let accent = Color(red: 0.93, green: 0.51, blue: 0.93) // #ED82ED
    
    // Glass Effects
    static let glass = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Backgrounds
    static let background = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.15, green: 0.05, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.6)
}

// GlassModifier.swift
import SwiftUI

struct GlassEffect: ViewModifier {
    var tint: Color = VioletTheme.glass
    var intensity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(tint)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(VioletTheme.glassBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: VioletTheme.primary.opacity(0.3),
                        radius: AppConstants.shadowRadius,
                        x: 0,
                        y: 10
                    )
            )
    }
}

extension View {
    func glassEffect(tint: Color = VioletTheme.glass, intensity: Double = 0.8) -> some View {
        self.modifier(GlassEffect(tint: tint, intensity: intensity))
    }
}


