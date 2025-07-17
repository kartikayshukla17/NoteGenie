//
//  AnimatedFeatureRow.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

struct AnimatedFeatureRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
                .symbolEffect(.bounce, options: .speed(1.5), value: animate)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animate)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        AnimatedFeatureRow(icon: "sparkles", text: "AI-powered content generation", delay: 0.1)
        AnimatedFeatureRow(icon: "play.rectangle", text: "YouTube transcript extraction", delay: 0.2)
        AnimatedFeatureRow(icon: "doc.text.viewfinder", text: "OCR text recognition", delay: 0.3)
    }
    .padding()
}