//
//  InsightsView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI
import Charts
import CoreHaptics

struct InsightsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedInsightType: InsightType = .activity
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    enum InsightType: String, CaseIterable {
        case activity = "Activity"
        case content = "Content"
        case tags = "Tags"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphicBackground()
                
                VStack(spacing: 16) {
                    // Segmented control for insight type
                    Picker("Insight Type", selection: $selectedInsightType) {
                        ForEach(InsightType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : -10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                    
                    // Time range selector - only show for Activity and Content insights
                    if selectedInsightType != .tags {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                    }
                    
                    // Content based on selected insight type
                    ScrollView {
                        VStack(spacing: 24) {
                            switch selectedInsightType {
                            case .activity:
                                ActivityInsightsView(timeRange: selectedTimeRange)
                            case .content:
                                ContentInsightsView()
                            case .tags:
                                TagInsightsView()
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Insights")
                .onAppear {
                    prepareHaptics()
                    withAnimation(.easeOut(duration: 0.5)) {
                        appearAnimation = true
                    }
                }
                .onChange(of: selectedInsightType) { _ in
                    playHapticFeedback(.selection)
                }
                .onChange(of: selectedTimeRange) { _ in
                    playHapticFeedback(.light)
                }
            }
        }
    }
}

struct ActivityInsightsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    let timeRange: InsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Activity summary card
            InsightCard(title: "Activity Summary") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 24) {
                        StatItem(value: "\(activeNotes.count)", label: "Active Notes")
                        StatItem(value: "\(notesCreatedInRange.count)", label: "Created")
                        StatItem(value: "\(notesEditedInRange.count)", label: "Edited")
                    }
                    
                    // Activity chart
                    Chart {
                        ForEach(activityData) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Count", data.count)
                            )
                            .foregroundStyle(Color.purple.gradient)
                        }
                    }
                    .frame(height: 180)
                    .chartYScale(domain: 0...(maxActivityCount + 1))
                }
            }
            
            // Productivity score card
            InsightCard(title: "Productivity Score") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 120, height: 120)
                        
                        // Animated progress circle
                        AnimatedCircleProgress(progress: CGFloat(productivityScore) / 100)
                            .frame(width: 120, height: 120)
                        
                        VStack {
                            // Animated counter
                            AnimatedCounter(value: Int(productivityScore))
                                .font(.system(size: 32, weight: .bold))
                            
                            Text("out of 100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Based on your note creation and editing frequency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Streak card
            InsightCard(title: "Current Streak") {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        VStack {
                            Text("\(currentStreak)")
                                .font(.system(size: 32, weight: .bold))
                            Text("days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Best: \(bestStreak) days", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("Keep creating notes daily to maintain your streak!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // Sample data - in a real app, this would be calculated from actual notes
    private var activeNotes: [Note] {
        notesViewModel.notes.filter { !$0.isDeleted }
    }
    
    private var notesCreatedInRange: [Note] {
        let startDate = startDateForRange
        return notesViewModel.notes.filter { $0.createdAt >= startDate }
    }
    
    private var notesEditedInRange: [Note] {
        let startDate = startDateForRange
        return notesViewModel.notes.filter { $0.updatedAt >= startDate && $0.updatedAt != $0.createdAt }
    }
    
    private var startDateForRange: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    private var activityData: [ActivityData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [ActivityData] = []
        
        let numberOfDays: Int
        switch timeRange {
        case .week: numberOfDays = 7
        case .month: numberOfDays = 30
        case .year: numberOfDays = 30 // For year, we'll show last 30 days for simplicity
        }
        
        for day in 0..<numberOfDays {
            let date = calendar.date(byAdding: .day, value: -day, to: now) ?? now
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            let count = notesViewModel.notes.filter { 
                ($0.createdAt >= startOfDay && $0.createdAt < endOfDay) ||
                ($0.updatedAt >= startOfDay && $0.updatedAt < endOfDay && $0.updatedAt != $0.createdAt)
            }.count
            
            result.append(ActivityData(date: startOfDay, count: count))
        }
        
        return result.reversed()
    }
    
    private var maxActivityCount: Int {
        activityData.map { $0.count }.max() ?? 0
    }
    
    // Sample productivity score - would be calculated based on actual usage
    private var productivityScore: Double {
        let totalDays = timeRange == .week ? 7 : (timeRange == .month ? 30 : 365)
        let activeDays = Set(activityData.filter { $0.count > 0 }.map { $0.date }).count
        
        return Double(activeDays) / Double(totalDays) * 100
    }
    
    // Sample streak data - would be calculated based on actual usage
    private var currentStreak: Int {
        let activeDates = activityData.filter { $0.count > 0 }.map { $0.date }
        var streak = 0
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 { // Check last 7 days
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            if activeDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var bestStreak: Int {
        return max(currentStreak, 5) // Sample data
    }
}

struct ContentInsightsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Content type distribution card
            InsightCard(title: "Content Type Distribution") {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(contentTypeData) { data in
                            SectorMark(
                                angle: .value("Count", data.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(data.color)
                            .cornerRadius(5)
                        }
                    }
                    .frame(height: 200)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(contentTypeData) { data in
                            HStack {
                                Circle()
                                    .fill(data.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(data.type)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(data.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Word count card
            InsightCard(title: "Word Count Statistics") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 24) {
                        StatItem(value: "\(totalWordCount)", label: "Total Words")
                        StatItem(value: "\(averageWordsPerNote)", label: "Avg per Note")
                    }
                    
                    // Most used words
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most Used Words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(mostUsedWords, id: \.self) { word in
                                Text(word)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Sample data - in a real app, this would be calculated from actual notes
    private var contentTypeData: [ContentTypeData] {
        // Get all blocks from all notes once to avoid repeated operations
        let allBlocks = notesViewModel.notes.flatMap { $0.contentBlocks }
        
        // Count blocks by type
        let textCount = allBlocks.filter { $0.type == .text }.count
        let imageCount = allBlocks.filter { $0.type == .image }.count
        let aiCount = allBlocks.filter { $0.type == .aiGenerated }.count
        let transcriptCount = allBlocks.filter { $0.type == .transcript }.count
        
        // Count other types
        let otherCount = allBlocks.filter { 
            $0.type == .pdfEmbed || $0.type == .ocrText 
        }.count
        
        // Create and return the data array
        return [
            ContentTypeData(type: "Text", count: textCount, color: .blue),
            ContentTypeData(type: "Images", count: imageCount, color: .green),
            ContentTypeData(type: "AI Generated", count: aiCount, color: .purple),
            ContentTypeData(type: "Transcripts", count: transcriptCount, color: .red),
            ContentTypeData(type: "Other", count: otherCount, color: .orange)
        ]
    }
    
    private var totalWordCount: Int {
        // Step 1: Get all content blocks from all notes
        let allBlocks = notesViewModel.notes.flatMap { $0.contentBlocks }
        
        // Step 2: Filter for text and AI-generated blocks
        let textBlocks = allBlocks.filter { 
            $0.type == .text || $0.type == .aiGenerated 
        }
        
        // Step 3: Count words in each block and sum them
        var total = 0
        for block in textBlocks {
            let words = block.content.split(separator: " ")
            total += words.count
        }
        
        return total
    }
    
    private var averageWordsPerNote: Int {
        guard !notesViewModel.notes.isEmpty else { return 0 }
        return totalWordCount / notesViewModel.notes.count
    }
    
    private var mostUsedWords: [String] {
        // In a real app, this would analyze actual content
        return ["note", "important", "meeting", "idea", "project"]
    }
}

struct TagInsightsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Tags usage card
            InsightCard(title: "Tags Usage") {
                VStack(spacing: 16) {
                    if notesViewModel.tags.isEmpty {
                        Text("No tags created yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(tagUsageData) { data in
                                BarMark(
                                    x: .value("Count", data.count),
                                    y: .value("Tag", data.name)
                                )
                                .foregroundStyle(data.color)
                            }
                        }
                        .frame(height: min(CGFloat(tagUsageData.count * 30), 200))
                    }
                }
            }
            
            // Tag recommendations card
            InsightCard(title: "Tag Recommendations") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Based on your notes content, consider adding these tags:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(recommendedTags, id: \.self) { tag in
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    createTag(tag)
                                }
                            }) {
                                HStack {
                                    Text(tag)
                                    Image(systemName: "plus")
                                        .font(.caption)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    // Sample data - in a real app, this would be calculated from actual notes
    private var tagUsageData: [TagUsageData] {
        notesViewModel.tags.map { tag in
            let count = notesViewModel.notes.filter { $0.tagIds.contains(tag.id) }.count
            return TagUsageData(id: tag.id, name: tag.name, count: count, color: tag.color)
        }.sorted { $0.count > $1.count }
    }
    
    private var recommendedTags: [String] {
        // In a real app, this would analyze note content to suggest tags
        return ["work", "personal", "ideas", "todo", "research"]
    }
    
    private func createTag(_ name: String) {
        // Create a new tag with a random color
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let randomColor = colors.randomElement() ?? .blue
        notesViewModel.createTag(name: name, color: randomColor)
    }
}

// Helper Views
struct InsightCard<Content: View>: View {
    let title: String
    let content: Content
    @State private var animate = false
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animate)
            
            content
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animate)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(animate ? 1 : 0)
        .scaleEffect(animate ? 1 : 0.95)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animate)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animate)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

// Data Models
struct ActivityData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct ContentTypeData: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    let color: Color
}

struct TagUsageData: Identifiable {
    let id: UUID
    let name: String
    let count: Int
    let color: Color
}

// Haptic feedback functions
extension InsightsView {
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }
    
    private func playHapticFeedback(_ type: HapticFeedbackType = .light) {
        switch type {
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(NotesViewModel())
}