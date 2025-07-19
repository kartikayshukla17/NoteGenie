//
//  ClaudNotesApp.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 14/07/25.
//

import SwiftUI

@main
struct ClaudNotesApp: App {
    
    init() {
        FirebaseConfig.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}