//
//  GeminiService.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import Foundation
import Combine

class GeminiService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: AppConstants.Keys.geminiAPIKey) ?? ""
    }
    
    // MARK: - AI Generation Methods
    func generateSummary(from content: String) async throws -> String {
        let prompt = """
        Please create a concise summary of the following content. Focus on the main points and key takeaways:
        
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    func generateFlashcards(from content: String) async throws -> String {
        let prompt = """
        Create flashcards from the following content. Format each flashcard as:
        
        **Q:** [Question]
        **A:** [Answer]
        
        Make sure to cover the most important concepts:
        
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    func generateQuiz(from content: String) async throws -> String {
        let prompt = """
        Create a quiz with multiple choice questions based on the following content. Format as:
        
        **Question 1:** [Question]
        A) [Option A]
        B) [Option B]
        C) [Option C]
        D) [Option D]
        **Answer:** [Correct option]
        
        Content:
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    func generateCornellNotes(from content: String) async throws -> String {
        let prompt = """
        Format the following content as Cornell Notes with these sections:
        
        **NOTES:**
        [Main notes and details]
        
        **CUES:**
        [Key terms, questions, and cues]
        
        **SUMMARY:**
        [Brief summary of main points]
        
        Content:
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    func generateQA(from content: String) async throws -> String {
        let prompt = """
        Create a Q&A format from the following content. Generate thoughtful questions and comprehensive answers:
        
        **Q:** [Question]
        **A:** [Detailed answer]
        
        Content:
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    func generateCustomContent(from content: String, instruction: String) async throws -> String {
        let prompt = """
        \(instruction)
        
        Content:
        \(content)
        """
        
        return try await generateContent(with: prompt)
    }
    
    // MARK: - Core API Method
    private func generateContent(with prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 2048
            )
        )
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw GeminiError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiError.apiError(errorData.error.message)
            } else {
                throw GeminiError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let candidate = geminiResponse.candidates.first,
                  let part = candidate.content.parts.first else {
                throw GeminiError.noContent
            }
            
            return part.text
        } catch {
            throw GeminiError.decodingError
        }
    }
}

// MARK: - Request Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
}

struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail
}

struct GeminiErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - Errors
enum GeminiError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case encodingError
    case networkError
    case apiError(String)
    case decodingError
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Gemini API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .networkError:
            return "Network error"
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .noContent:
            return "No content generated"
        }
    }
}

// MARK: - AI Generation Type Extensions
extension AIGenerationType {
    var description: String {
        switch self {
        case .summary: return "Generate a concise summary"
        case .flashcards: return "Create study flashcards"
        case .quiz: return "Generate quiz questions"
        case .cornell: return "Format as Cornell notes"
        case .qa: return "Create Q&A pairs"
        case .custom: return "Custom instruction"
        }
    }
    
    var icon: String {
        switch self {
        case .summary: return "doc.text"
        case .flashcards: return "rectangle.stack"
        case .quiz: return "questionmark.circle"
        case .cornell: return "doc.richtext"
        case .qa: return "bubble.left.and.bubble.right"
        case .custom: return "wand.and.stars"
        }
    }
}
