import SwiftUI

/// View for the fullscreen countdown overlay (5, 4, 3, 2, 1)
struct CountdownOverlayView: View {
    @Bindable var timerManager: TimerManager
    
    var body: some View {
        ZStack {
            // No full-screen background; let the transparent window show through
            Color.clear
            
            if timerManager.showCountdownOverlay {
                VStack(spacing: 20) {
                if let message = timerManager.autoTransitionMessage {
                    // Auto transition message
                    Text(message)
                        .font(.system(size: 60, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .padding(.vertical, 40)
                } else if timerManager.isWaitingForAction {
                    // Action Buttons when session is complete
                    VStack(spacing: 16) {
                        Text(titleForSession(timerManager.currentSession))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.85))
                            
                        Text(subtitleForSession(timerManager.currentSession))
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.5))
                    }
                    .padding(.bottom, 30)
                        
                    HStack(spacing: 40) {
                        Button(action: { timerManager.overlayActionContinue() }) {
                            Text(timerManager.currentSession == .work ? "开始休息了" : "继续工作吧")
                        }
                        .buttonStyle(OverlayButtonStyle(bg: Color.blue.opacity(0.15), fg: .blue))
                        
                        Button(action: { timerManager.overlayActionPause() }) {
                            Text("暂停下阶段")
                        }
                        .buttonStyle(OverlayButtonStyle(bg: Color.black.opacity(0.05), fg: Color.black.opacity(0.7)))
                    }
                } else {
                    // Countdown
                    let number = timerManager.countdownNumber
                    Text("\(number)")
                        .font(.system(size: 300, weight: .bold, design: .rounded))
                        .foregroundStyle(timerManager.currentSession == .work ? .black.opacity(0.85) : .green.opacity(0.85))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: number)
                    
                    Text(timerManager.currentSession == .work ? "工作即将结束" : "休息即将结束")
                        .font(.system(size: 50, weight: .medium, design: .rounded))
                        .foregroundStyle(timerManager.currentSession == .work ? .black.opacity(0.6) : .green.opacity(0.6))
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
            // Use native macOS material for the rounded background
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 60, style: .continuous))
            // Add a subtle shadow to separate it from whatever is behind
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helpers
    
    private func titleForSession(_ session: SessionType) -> String {
        switch session {
        case .work: return "工作结束！"
        case .shortBreak: return "休息结束！"
        case .longBreak: return "长休息结束！"
        }
    }
    
    private func subtitleForSession(_ session: SessionType) -> String {
        switch session {
        case .work: return "做得好！该休息一下了。"
        case .shortBreak: return "准备好再次专注了吗？"
        case .longBreak: return "感觉神清气爽？我们继续工作吧！"
        }
    }
}

/// A custom button style that provides visual feedback (scale and opacity) on press
struct OverlayButtonStyle: ButtonStyle {
    var bg: Color
    var fg: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 32, weight: .medium))
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Capsule().fill(bg))
            .foregroundStyle(fg)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    Group {
        let settings = SettingsManager()
        CountdownOverlayView(timerManager: TimerManager(settings: settings))
    }
    .background(.black)
}
