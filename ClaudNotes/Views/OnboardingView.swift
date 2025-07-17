//
//  OnboardingView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI
import CoreHaptics

struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // Define onboarding pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to ClaudNotes",
            subtitle: "Your AI-powered note-taking companion",
            description: "Create, organize, and enhance your notes with the power of AI",
            systemImage: "note.text",
            accentColor: .indigo
        ),
        OnboardingPage(
            title: "AI-Powered Features",
            subtitle: "Let AI do the heavy lifting",
            description: "Generate summaries, flashcards, quizzes, and more from your notes with a single tap",
            systemImage: "sparkles",
            accentColor: .purple
        ),
        OnboardingPage(
            title: "YouTube Integration",
            subtitle: "Extract content from videos",
            description: "Automatically create notes from YouTube videos with transcripts and key points",
            systemImage: "play.rectangle.fill",
            accentColor: .red
        ),
        OnboardingPage(
            title: "Organize Your Way",
            subtitle: "Folders, tags, and more",
            description: "Keep your notes organized with folders and tags for easy retrieval",
            systemImage: "folder.fill",
            accentColor: .blue
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Skip button
                    HStack {
                        Spacer()
                        
                        Button("Skip") {
                            HapticFeedback.medium()
                            withAnimation {
                                isShowingOnboarding = false
                            }
                        }
                        .font(.body.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding()
                    }
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // Bottom navigation
                    VStack(spacing: 24) {
                        // Page indicator
                        PageIndicator(
                            pageCount: pages.count,
                            currentPage: currentPage
                        )
                        
                        // Navigation buttons
                        if currentPage < pages.count - 1 {
                            Button {
                                HapticFeedback.light()
                                withAnimation {
                                    currentPage += 1
                                }
                            } label: {
                                Text("Continue")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(pages[currentPage].accentColor)
                            .padding(.horizontal, 20)
                        } else {
                            Button {
                                HapticFeedback.medium()
                                withAnimation {
                                    isShowingOnboarding = false
                                }
                            } label: {
                                Text("Get Started")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(pages[currentPage].accentColor)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 24 : 32)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let accentColor: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Image
            Image(systemName: page.systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(page.accentColor.gradient)
                .padding(30)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: page.accentColor.opacity(0.3), radius: 15, x: 0, y: 5)
                )
                .opacity(isAnimated ? 1 : 0)
                .scaleEffect(isAnimated ? 1 : 0.7)
                .symbolEffect(.bounce, options: .speed(1), value: isAnimated)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(page.accentColor.gradient)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 20)
                
                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 15)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 10)
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
        .onChange(of: page.title) { _ in
            isAnimated = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: currentPage == index ? 16 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

#Preview {
    OnboardingView(isShowingOnboarding: .constant(true))
        .environmentObject(NotesViewModel())
}