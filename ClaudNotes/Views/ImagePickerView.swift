//
//  ImagePickerView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import PhotosUI
import Vision

struct ImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 24) {
                    if let selectedImage = selectedImage {
                        // Image Preview
                        VStack(spacing: 16) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 10)
                            
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Extracting text...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if !extractedText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Extracted Text:")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    ScrollView {
                                        Text(extractedText)
                                            .font(.body)
                                            .textSelection(.enabled)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                            )
                                    }
                                    .frame(maxHeight: 200)
                                }
                            }
                        }
                    } else {
                        // Image Selection Options
                        VStack(spacing: 32) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                            
                            VStack(spacing: 16) {
                                Text("Select Image Source")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Choose an image to extract text using OCR")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(spacing: 16) {
                                // Photo Library Button
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    ImageSourceButton(
                                        title: "Photo Library",
                                        subtitle: "Choose from your photos",
                                        icon: "photo.on.rectangle",
                                        color: .blue
                                    )
                                }
                                
                                // Camera Button
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    ImageSourceButton(
                                        title: "Camera",
                                        subtitle: "Take a new photo",
                                        icon: "camera.fill",
                                        color: .green
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    if selectedImage != nil {
                        HStack(spacing: 16) {
                            Button("Choose Different") {
                                selectedImage = nil
                                selectedItem = nil
                                extractedText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Use Text") {
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
            .navigationTitle("Extract Text from Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem {
                    await loadImage(from: newItem)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                selectedImage = image
                performOCR(on: image)
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        
        await MainActor.run {
            selectedImage = image
            performOCR(on: image)
        }
    }
    
    private func performOCR(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessing = true
        extractedText = ""
        
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    print("OCR Error: \(error)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                extractedText = recognizedStrings.joined(separator: "\n")
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    print("Failed to perform OCR: \(error)")
                }
            }
        }
    }
}

struct ImageSourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
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
}

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ImagePickerView()
}