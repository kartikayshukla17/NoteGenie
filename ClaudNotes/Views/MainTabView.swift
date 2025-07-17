//
//  MainTabView.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI
import CoreHaptics

struct MainTabView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var showingSettings = false
    @State private var showingCreateOptions = false
    @State private var showingInsights = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var searchText = ""
    @State private var hapticEngine: CHHapticEngine?
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar with folders
            ZStack {
                GlassmorphicBackground()
                
                FoldersView()
            }
            .navigationTitle("ClaudNotes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            notesViewModel.createNote()
                        }) {
                            Label("New Note", systemImage: "square.and.pencil")
                        }
                        
                        Button(action: {
                            showingInsights = true
                        }) {
                            Label("Insights", systemImage: "chart.bar.fill")
                        }
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } content: {
            // Content column with notes list
            ZStack {
                GlassmorphicBackground()
                
                NotesListView()
                    .searchable(text: $searchText, prompt: "Search notes")
                    .onChange(of: searchText) { newValue in
                        notesViewModel.searchText = newValue
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: {
                                    notesViewModel.createNote()
                                }) {
                                    Label("Text Note", systemImage: "square.and.pencil")
                                }
                                
                                Button(action: {
                                    showingCreateOptions = true
                                }) {
                                    Label("More Options", systemImage: "ellipsis.circle")
                                }
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .font(.title3)
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Button(action: {
                                    columnVisibility = .all
                                }) {
                                    Image(systemName: "sidebar.left")
                                }
                            }
                        }
                    }
            }
        } detail: {
            // Detail view showing selected note or empty state
            ZStack {
                GlassmorphicBackground()
                
                if let selectedNote = notesViewModel.selectedNote {
                    NoteDetailView(note: selectedNote)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.purple.opacity(0.6))
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                            .symbolEffect(.pulse, options: .repeating.speed(0.7), value: appearAnimation)
                        
                        Text("No Note Selected")
                            .font(.title2)
                            .fontWeight(.medium)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                        
                        Text("Select a note from the list or create a new one")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                        
                        Button(action: {
                            playHapticFeedback(.light)
                            notesViewModel.createNote()
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("New Note")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 20)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 15)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appearAnimation)
                    }
                    .padding()
                }
            }
            .toolbar {
                if let selectedNote = notesViewModel.selectedNote {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                notesViewModel.pinNote(selectedNote)
                            }) {
                                if selectedNote.isPinned {
                                    Label("Unpin", systemImage: "pin.slash")
                                } else {
                                    Label("Pin", systemImage: "pin")
                                }
                            }
                            
                            Menu {
                                ForEach(notesViewModel.folders) { folder in
                                    Button(action: {
                                        notesViewModel.moveNote(selectedNote, to: folder)
                                    }) {
                                        Label(folder.name, systemImage: "folder")
                                    }
                                }
                                
                                Button(action: {
                                    notesViewModel.moveNote(selectedNote, to: nil)
                                }) {
                                    Label("None", systemImage: "tray")
                                }
                            } label: {
                                Label("Move to Folder", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                notesViewModel.softDeleteNote(selectedNote)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .accentColor(.purple)
        .onAppear {
            prepareHaptics()
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingCreateOptions) {
            CreateNoteView()
        }
        .sheet(isPresented: $showingInsights) {
            InsightsView()
        }
    }
    
    // Haptic feedback functions
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
    MainTabView()
        .environmentObject(NotesViewModel())
}