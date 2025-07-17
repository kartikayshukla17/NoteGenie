//
//  GlassmorphicBackground.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct GlassmorphicBackground: View {
    @State private var animateGradient = false
    @State private var animateBlobs = false
    @State private var rotateBlobs = false
    @State private var pulseOpacity = false
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated gradient blobs
            ZStack {
                // Purple blob
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(pulseOpacity ? 0.7 : 0.6), .purple.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: -50, y: animateGradient ? -100 : -150)
                    .scaleEffect(animateBlobs ? 1.1 : 1.0)
                    .rotationEffect(Angle(degrees: rotateBlobs ? 15 : 0))
                    .blur(radius: 60)
                
                // Pink blob
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(pulseOpacity ? 0.7 : 0.6), .pink.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 250, height: 250)
                    .offset(x: 100, y: animateGradient ? 150 : 100)
                    .scaleEffect(animateBlobs ? 0.9 : 1.0)
                    .rotationEffect(Angle(degrees: rotateBlobs ? -10 : 0))
                    .blur(radius: 60)
                
                // Blue blob
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(pulseOpacity ? 0.7 : 0.6), .blue.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: animateGradient ? 50 : 0, y: -200)
                    .scaleEffect(animateBlobs ? 1.05 : 0.95)
                    .rotationEffect(Angle(degrees: rotateBlobs ? 5 : -5))
                    .blur(radius: 60)
                
                // Additional cyan blob for more dynamic feel
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(pulseOpacity ? 0.5 : 0.4), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .offset(x: animateGradient ? -120 : -80, y: 180)
                    .scaleEffect(animateBlobs ? 1.1 : 0.9)
                    .rotationEffect(Angle(degrees: rotateBlobs ? -15 : 0))
                    .blur(radius: 50)
            }
            .onAppear {
                // Multiple animations with different timings for a more organic feel
                withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
                
                withAnimation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animateBlobs.toggle()
                }
                
                withAnimation(Animation.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                    rotateBlobs.toggle()
                }
                
                withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    pulseOpacity.toggle()
                }
            }
            
            // Noise overlay for texture
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .blendMode(.multiply)
                .ignoresSafeArea()
        }
    }
}

// A simpler version for list backgrounds and other components
struct SimpleGlassmorphicBackground: View {
    var body: some View {
        ZStack {
            // Base color
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    .purple.opacity(0.2),
                    .pink.opacity(0.1),
                    .blue.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Noise overlay for texture
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .blendMode(.multiply)
                .ignoresSafeArea()
        }
    }
}

// Glass card effect for components
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCard())
    }
}

#Preview {
    GlassmorphicBackground()
}