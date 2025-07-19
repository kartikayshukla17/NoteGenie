//
//  SyncStatusView.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var firebaseService = FirebaseService.shared
    @ObservedObject var notesFirebaseService = NotesFirebaseService.shared
    @ObservedObject var storageService = StorageService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(firebaseService.isConnected ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: firebaseService.isConnected)
                
                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Loading indicator
            if notesFirebaseService.isLoading || storageService.isUploading {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text(loadingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Upload progress
            if !storageService.uploadProgress.isEmpty {
                HStack(spacing: 6) {
                    ProgressView(value: averageUploadProgress)
                        .frame(width: 40)
                    
                    Text("\(Int(averageUploadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private var connectionStatusColor: Color {
        if firebaseService.currentUserId == nil {
            return .orange
        } else if firebaseService.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    private var connectionStatusText: String {
        if firebaseService.currentUserId == nil {
            return "Not signed in"
        } else if firebaseService.isConnected {
            return "Connected"
        } else {
            return "Offline"
        }
    }
    
    private var loadingText: String {
        if storageService.isUploading {
            return "Uploading..."
        } else if notesFirebaseService.isLoading {
            return "Syncing..."
        } else {
            return "Loading..."
        }
    }
    
    private var averageUploadProgress: Double {
        let progressValues = Array(storageService.uploadProgress.values)
        guard !progressValues.isEmpty else { return 0.0 }
        return progressValues.reduce(0, +) / Double(progressValues.count)
    }
}

struct DetailedSyncStatusView: View {
    @ObservedObject var firebaseService = FirebaseService.shared
    @ObservedObject var notesFirebaseService = NotesFirebaseService.shared
    @ObservedObject var storageService = StorageService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Connection Status Section
                Section("Connection Status") {
                    HStack {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connectionStatusText)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let userId = firebaseService.currentUserId {
                                Text("User ID: \(userId.prefix(8))...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if firebaseService.isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                // Data Status Section
                Section("Data Status") {
                    DataStatusRow(
                        title: "Notes",
                        count: notesFirebaseService.notes.count,
                        isLoading: notesFirebaseService.isLoading
                    )
                    
                    DataStatusRow(
                        title: "Folders",
                        count: notesFirebaseService.folders.count,
                        isLoading: notesFirebaseService.isLoading
                    )
                    
                    DataStatusRow(
                        title: "Tags",
                        count: notesFirebaseService.tags.count,
                        isLoading: notesFirebaseService.isLoading
                    )
                }
                
                // Upload Status Section
                if !storageService.uploadProgress.isEmpty {
                    Section("Upload Progress") {
                        ForEach(Array(storageService.uploadProgress.keys), id: \.self) { path in
                            let progress = storageService.uploadProgress[path] ?? 0.0
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(URL(fileURLWithPath: path).lastPathComponent)
                                        .font(.body)
                                        .lineLimit(1)
                                    
                                    Text(path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(progress * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    ProgressView(value: progress)
                                        .frame(width: 60)
                                }
                            }
                        }
                    }
                }
                
                // Error Status Section
                if let error = notesFirebaseService.error ?? storageService.error {
                    Section("Errors") {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync Error")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Clear") {
                                notesFirebaseService.clearError()
                                storageService.clearError()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Data")
                        }
                    }
                    .disabled(notesFirebaseService.isLoading)
                    
                    if firebaseService.currentUserId == nil {
                        Button {
                            // Navigate to authentication
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("Sign In")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var connectionStatusColor: Color {
        if firebaseService.currentUserId == nil {
            return .orange
        } else if firebaseService.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    private var connectionStatusText: String {
        if firebaseService.currentUserId == nil {
            return "Not signed in"
        } else if firebaseService.isConnected {
            return "Connected to Firebase"
        } else {
            return "Offline mode"
        }
    }
    
    private func refreshData() async {
        await notesFirebaseService.refreshData()
    }
}

struct DataStatusRow: View {
    let title: String
    let count: Int
    let isLoading: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text("\(count)")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusView()
        
        Button("Show Details") {
            // Preview action
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}