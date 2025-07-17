//
//  CoreServices.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Service Container
final class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    lazy var youtubeService = YouTubeService()
    lazy var geminiService = GeminiService()
    lazy var apiStatusChecker = APIStatusChecker()
    
    private init() {}
}

// MARK: - API Status Checker
class APIStatusChecker: ObservableObject {
    @Published var geminiConfigured = false
    @Published var youtubeConfigured = false
    
    init() {
        checkAPIStatus()
        
        // Listen for UserDefaults changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func userDefaultsDidChange() {
        DispatchQueue.main.async {
            self.checkAPIStatus()
        }
    }
    
    func checkAPIStatus() {
        geminiConfigured = !(UserDefaults.standard.string(forKey: AppConstants.Keys.geminiAPIKey)?.isEmpty ?? true)
        youtubeConfigured = !(UserDefaults.standard.string(forKey: AppConstants.Keys.youtubeAPIKey)?.isEmpty ?? true)
    }
    
    var allConfigured: Bool {
        geminiConfigured && youtubeConfigured
    }
    
    var configurationMessage: String {
        if allConfigured {
            return "All APIs configured ✅"
        } else {
            var missing: [String] = []
            if !geminiConfigured { missing.append("Gemini AI") }
            if !youtubeConfigured { missing.append("YouTube") }
            return "Missing: \(missing.joined(separator: ", "))"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Error Handling
struct AppError: Error, LocalizedError, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let code: Int?
    
    var errorDescription: String? {
        return message
    }
    
    static let noAPIKey = AppError(
        title: "API Key Missing",
        message: "Please configure your API keys in Settings",
        code: 1001
    )
    
    static let networkError = AppError(
        title: "Network Error",
        message: "Please check your internet connection",
        code: 1002
    )
    
    static let invalidData = AppError(
        title: "Invalid Data",
        message: "The data received is invalid",
        code: 1003
    )
    
    static func custom(_ message: String) -> AppError {
        AppError(
            title: "Error",
            message: message,
            code: nil
        )
    }
}

// MARK: - Loading States
enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case error(AppError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var error: AppError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.id == rhsError.id
        default:
            return false
        }
    }
}

// MARK: - Environment Extensions
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func withServices() -> some View {
        self.environment(\.serviceContainer, ServiceContainer.shared)
    }
}