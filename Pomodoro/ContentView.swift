import SwiftUI

struct ContentView: View {
    @Bindable var timerManager: TimerManager
    @Bindable var settings: SettingsManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("\(timerManager.currentSession.iconEmoji) Pomodoro")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Settings button
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                        .modifier(IconPressAction(action: { showSettings.toggle() }))
                        .help("Settings")
                        .popover(isPresented: $showSettings) {
                            SettingsView(settings: settings) {
                                timerManager.refreshDuration()
                            }
                        }
                    
                    // Reset all button
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                        .modifier(IconPressAction(action: { timerManager.resetAll() }))
                        .help("Reset all")
                }
            }
            
            Divider()
            
            // Timer Display
            VStack(spacing: 8) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.1)
                        .foregroundStyle(sessionColor)
                    
                    Circle()
                        .trim(from: 0.0, to: timerManager.progress)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(sessionColor)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerManager.progress)
                    
                    VStack(spacing: 4) {
                        Text(timerManager.formattedTime)
                            .font(.system(size: 42, weight: .medium, design: .monospaced))
                        
                        Text(timerManager.currentSession.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 160)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                // Reset button
                CircleButton(
                    icon: "arrow.counterclockwise",
                    size: 44,
                    color: .quaternary,
                    action: { timerManager.reset() },
                    help: "Reset timer"
                )
                
                // Play/Pause button
                CircleButton(
                    icon: timerManager.isRunning ? "pause.fill" : "play.fill",
                    size: 56,
                    color: AnyShapeStyle(sessionColor),
                    iconColor: .white,
                    action: { timerManager.toggle() },
                    help: timerManager.isRunning ? "Pause" : "Start"
                )
                
                // Skip button
                CircleButton(
                    icon: "forward.fill",
                    size: 44,
                    color: .quaternary,
                    action: { timerManager.skip() },
                    help: "Skip to next session"
                )
            }
            
            Divider()
            
            // Session Counter
            HStack(alignment: .firstTextBaseline) {
                Text("Completed:")
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        let cycleCount = timerManager.completedPomodoros % 4
                        let isFilled = index < cycleCount || (cycleCount == 0 && timerManager.completedPomodoros > 0 && index < 4)
                        Image(systemName: isFilled ? "circle.fill" : "circle")
                            .foregroundStyle(isFilled ? .primary : .quaternary)
                            .font(.system(size: 11))
                    }
                }
                
                Spacer()
                
                Text("\(timerManager.completedPomodoros) total")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            
            // Auto-mode toggle
            Toggle(isOn: $timerManager.isAutoMode) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                    Text("Auto-start next session")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .toggleStyle(.checkbox)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            
            // Quit button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .padding(20)
        .frame(width: 240)
    }
    
    private var sessionColor: Color {
        switch timerManager.currentSession {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
}

#Preview {
    ContentView(timerManager: TimerManager(settings: SettingsManager()), settings: SettingsManager())
}

// MARK: - Press Action Modifier (For buttons with existing background)
struct PressAction: ViewModifier {
    let action: () -> Void
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .brightness(isPressed ? 0.3 : 0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
    }
}

// MARK: - Icon Press Action Modifier (For icon-only buttons)
struct IconPressAction: ViewModifier {
    let action: () -> Void
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .background {
                Circle()
                    .fill(.quaternary)
                    .opacity(isPressed ? 1 : 0)
            }
            .contentShape(Circle())
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
    }
}

// MARK: - Circle Button Component
struct CircleButton: View {
    let icon: String
    let size: CGFloat
    let color: AnyShapeStyle
    var iconColor: Color = .primary
    let action: () -> Void
    let help: String
    
    init(icon: String, size: CGFloat, color: some ShapeStyle, iconColor: Color = .primary, action: @escaping () -> Void, help: String) {
        self.icon = icon
        self.size = size
        self.color = AnyShapeStyle(color)
        self.iconColor = iconColor
        self.action = action
        self.help = help
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(size > 50 ? .title : .title2)
                    .foregroundStyle(iconColor)
            }
            .modifier(PressAction(action: action))
            .help(help)
    }
}
