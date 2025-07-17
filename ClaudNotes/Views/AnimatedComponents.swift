//
//  AnimatedComponents.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import SwiftUI

// Animated circle progress component
struct AnimatedCircleProgress: View {
    let progress: CGFloat
    @State private var animatedProgress: CGFloat = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: animatedProgress)
            .stroke(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 10, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { newValue in
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = newValue
                }
            }
    }
}

// Animated counter component
struct AnimatedCounter: View {
    let value: Int
    @State private var animatedValue: Int = 0
    
    var body: some View {
        Text("\(animatedValue)")
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    // Animate from 0 to the target value
                    animateValue()
                }
            }
            .onChange(of: value) { newValue in
                withAnimation(.easeOut(duration: 1.0)) {
                    animateValue()
                }
            }
    }
    
    private func animateValue() {
        // Reset to 0 if the value is significantly different
        if abs(value - animatedValue) > value / 2 {
            animatedValue = 0
        }
        
        // Use a timer to create a counting effect
        let stepDuration = 1.5 / Double(value)
        let steps = value - animatedValue
        
        if steps > 0 {
            var currentStep = 0
            Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
                animatedValue += 1
                currentStep += 1
                
                if currentStep >= steps {
                    timer.invalidate()
                }
            }
        }
    }
}

// Animated bar chart component
struct AnimatedBarChart: View {
    let data: [Double]
    let maxValue: Double
    let barColor: Color
    @State private var animatedHeights: [Double]
    
    init(data: [Double], maxValue: Double? = nil, barColor: Color = .blue) {
        self.data = data
        self.maxValue = maxValue ?? (data.max() ?? 1.0)
        self.barColor = barColor
        self._animatedHeights = State(initialValue: Array(repeating: 0, count: data.count))
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<data.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(height: CGFloat(animatedHeights[index] / maxValue) * 150)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animatedHeights[index])
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedHeights = data
            }
        }
        .onChange(of: data) { newData in
            withAnimation(.easeOut(duration: 1.0)) {
                if newData.count == animatedHeights.count {
                    animatedHeights = newData
                } else {
                    // Handle case where array size changes
                    animatedHeights = Array(repeating: 0, count: newData.count)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            animatedHeights = newData
                        }
                    }
                }
            }
        }
    }
}

// Animated number ticker for smooth transitions between values
struct AnimatedNumberTicker: View {
    let value: Double
    let format: String
    @State private var animatedValue: Double = 0
    
    init(value: Double, format: String = "%.0f") {
        self.value = value
        self.format = format
    }
    
    var body: some View {
        Text(String(format: format, animatedValue))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { newValue in
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValue = newValue
                }
            }
    }
}