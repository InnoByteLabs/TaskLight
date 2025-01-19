//
//  TaskLightIcon.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI

struct TaskLightIcon: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0), // Light blue
                    Color(red: 0.1, green: 0.4, blue: 0.8)  // Darker blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Task list visual
            VStack(spacing: 12) {
                // Checkmark in circle
                Circle()
                    .fill(Color.yellow.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // Simplified task lines
                VStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.8 - Double(i) * 0.2))
                            .frame(width: 70, height: 6)
                    }
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

#Preview {
    TaskLightIcon()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
