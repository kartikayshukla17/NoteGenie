//
//  ButtonStyles.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

/// A button style that applies a subtle scale effect when pressed
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A button style that applies a bounce effect when pressed
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A button style that applies a glow effect when pressed
struct GlowButtonStyle: ButtonStyle {
    var glowColor: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(color: configuration.isPressed ? glowColor.opacity(0.5) : glowColor.opacity(0), 
                    radius: configuration.isPressed ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}