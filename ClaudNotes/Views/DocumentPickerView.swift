//
//  DocumentPickerView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDocument: URL?
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var showingDocumentPicker = false
    @State private var documentTitle = ""
    @State private var documentType: DocumentType = .unknown
    
    enum DocumentType {
        case pdf
        case text
        case unknown
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .text: return "doc.text"
            case .unknown: return "doc"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .text: return .blue
            case .unknown: return .gray
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    if let selectedDocument = selectedDocument {
                        // Document Preview
                        VStack(spacing: 16) {
                            // Document Info
                            HStack(spacing: 16) {
                                Image(systemName: documentType.icon)
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(documentType.color)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(documentTitle)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .lineLimit(2)
                                    
                                    Text(selectedDocument.lastPathComponent)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Processing Status
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Extracting text from document...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            
                            // Extracted Text
                            if !extractedText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Extracted Text:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text("\(extractedText.count) characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    ScrollView {
                                        Text(extractedText)
                                            .font(.body)
                                            .textSelection(.enabled)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .frame(maxHeight: 300)
                                }
                            }
                        }
                    } else {
                        // Document Selection
                        VStack(spacing: 32) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)
                            
                            VStack(spacing: 16) {
                                Text("Import Document")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Select a PDF or text document to extract content")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(spacing: 16) {
                                DocumentTypeButton(
                                    title: "PDF Documents",
                                    subtitle: "Extract text from PDF files",
                                    icon: "doc.fill",
                                    color: .red,
                                    supportedTypes: [.pdf]
                                ) {
                                    showingDocumentPicker = true
                                }
                                
                                DocumentTypeButton(
                                    title: "Text Documents",
                                    subtitle: "Import .txt, .rtf, and other text files",
                                    icon: "doc.text",
                                    color: .blue,
                                    supportedTypes: [.plainText, .rtf, .text]
                                ) {
                                    showingDocumentPicker = true
                                }
                                
                                DocumentTypeButton(
                                    title: "All Documents",
                                    subtitle: "Browse all supported file types",
                                    icon: "folder",
                                    color: .purple,
                                    supportedTypes: [.pdf, .plainText, .rtf, .text]
                                ) {
                                    showingDocumentPicker = true
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    if selectedDocument != nil {
                        HStack(spacing: 16) {
                            Button("Choose Different") {
                                resetSelection()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Use Content") {
                                // TODO: Add extracted text to note
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(extractedText.isEmpty)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Import Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .rtf, .text],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentSelection(result)
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedDocument = url
            documentTitle = url.deletingPathExtension().lastPathComponent
            
            // Determine document type
            let pathExtension = url.pathExtension.lowercased()
            switch pathExtension {
            case "pdf":
                documentType = .pdf
            case "txt", "rtf":
                documentType = .text
            default:
                documentType = .unknown
            }
            
            extractTextFromDocument(url)
            
        case .failure(let error):
            print("Document selection failed: \(error)")
        }
    }
    
    private func extractTextFromDocument(_ url: URL) {
        isProcessing = true
        extractedText = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            var text = ""
            
            if url.pathExtension.lowercased() == "pdf" {
                text = extractTextFromPDF(url)
            } else {
                text = extractTextFromTextFile(url)
            }
            
            DispatchQueue.main.async {
                isProcessing = false
                extractedText = text
            }
        }
    }
    
    private func extractTextFromPDF(_ url: URL) -> String {
        guard let document = PDFDocument(url: url) else {
            return "Failed to load PDF document"
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                if let pageText = page.string {
                    extractedText += pageText + "\n\n"
                }
            }
        }
        
        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTextFromTextFile(_ url: URL) -> String {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            return "Failed to read text file: \(error.localizedDescription)"
        }
    }
    
    private func resetSelection() {
        selectedDocument = nil
        extractedText = ""
        documentTitle = ""
        documentType = .unknown
        isProcessing = false
    }
}

struct DocumentTypeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let supportedTypes: [UTType]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DocumentPickerView()
}