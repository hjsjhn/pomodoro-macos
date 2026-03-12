import SwiftUI

/// View for the fullscreen countdown overlay (5, 4, 3, 2, 1)
struct CountdownOverlayView: View {
    let number: Int
    let sessionType: SessionType
    
    var body: some View {
        ZStack {
            // No full-screen background; let the transparent window show through
            Color.clear
            
            VStack(spacing: 20) {
                // Colorful number based on session
                Text("\(number)")
                    .font(.system(size: 300, weight: .bold, design: .rounded))
                    .foregroundStyle(sessionType == .work ? .black.opacity(0.85) : .green.opacity(0.85))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: number)
                
                // Explanatory text
                Text(sessionType == .work ? "工作即将结束" : "休息即将结束")
                    .font(.system(size: 50, weight: .medium, design: .rounded))
                    .foregroundStyle(sessionType == .work ? .black.opacity(0.6) : .green.opacity(0.6))
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
            // Use native macOS material for the rounded background
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 60, style: .continuous))
            // Add a subtle shadow to separate it from whatever is behind
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Group {
        CountdownOverlayView(number: 5, sessionType: .work)
        CountdownOverlayView(number: 3, sessionType: .shortBreak)
    }
    .background(.black)
}
