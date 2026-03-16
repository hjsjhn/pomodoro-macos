import SwiftUI
import AppKit

/// View for the fullscreen countdown overlay
struct CountdownOverlayView: View {
    @Bindable var timerManager: TimerManager
    
    @State private var showExitPrompt = false
    @State private var exitText = ""
    @State private var pressedKeys: Set<UInt16> = []
    @State private var clickCount = 0
    @State private var shortcutUnlocked = false
    @State private var recentKeyTimestamps: [Date] = []
    
    private let requiredClicks = 10
    // Keyboard mashing: 8 keystrokes within 3 seconds
    private let mashKeyCount = 15
    private let mashTimeWindow: TimeInterval = 1.0
    
    let requiredExitPhrase = "I understand the importance of this break, but I must skip it."
    
    // Key codes for E, S, C
    private let escKeyE: UInt16 = 14   // E
    private let escKeyS: UInt16 = 1    // S
    private let escKeyC: UInt16 = 8    // C
    
    private func checkEmergencyShortcut(flags: NSEvent.ModifierFlags) -> Bool {
        guard shortcutUnlocked else { return false }
        let hasModifiers = flags.contains([.control, .command, .shift])
        let hasAllKeys = pressedKeys.contains(escKeyE) && pressedKeys.contains(escKeyS) && pressedKeys.contains(escKeyC)
        return hasModifiers && hasAllKeys
    }
    
    /// Detects keyboard mashing: many keystrokes in a short time window
    private func recordKeystroke() {
        let now = Date()
        recentKeyTimestamps.append(now)
        // Trim old timestamps outside the window
        recentKeyTimestamps = recentKeyTimestamps.filter { now.timeIntervalSince($0) <= mashTimeWindow }
        if recentKeyTimestamps.count >= mashKeyCount {
            shortcutUnlocked = true
        }
    }
    
    var isForcedBreakActive: Bool {
        return timerManager.settings.isForcedBreakEnabled && timerManager.currentSession != .work && !timerManager.isWaitingForAction
    }
    
    var body: some View {
        ZStack {
            if isForcedBreakActive {
                // Dark blurred background for forced breaks
                Color.black.opacity(0.3)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            } else {
                // No full-screen background; let the transparent window show through
                Color.clear
            }
            
            if timerManager.showCountdownOverlay {
                if isForcedBreakActive {
                    // Fullscreen forced break UI
                    VStack(spacing: 30) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 80))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(timerManager.currentSession.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text(timerManager.formattedTime)
                            .font(.system(size: 120, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                        
                        if showExitPrompt {
                            VStack(spacing: 16) {
                                Text("Type the following phrase exactly to force exit:")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                Text(requiredExitPhrase)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                TextField("Type here...", text: $exitText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(maxWidth: 600)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .onChange(of: exitText) { _, newValue in
                                        if newValue == requiredExitPhrase {
                                            exitText = ""
                                            showExitPrompt = false
                                            timerManager.pause()
                                        }
                                    }
                            }
                            .padding(.top, 40)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            Text("Take a deep breath and step away from the screen.")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 8) {
                            // Subtle emergency exit trigger
                            if !showExitPrompt {
                                Button("Emergency Exit") {
                                    withAnimation(.spring(duration: 0.4)) {
                                        showExitPrompt = true
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                                .onHover { hovering in
                                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                                }
                            }
                            
                            // Shortcut hint — only visible once unlocked
                            if shortcutUnlocked {
                                Text("⌃⇧⌘ + E+S+C to exit")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .transition(.opacity)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    // Normal countdown or action box content
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
        }
        .onChange(of: timerManager.currentSession) { _, _ in
            // Reset all exit-related state for each new session
            shortcutUnlocked = false
            clickCount = 0
            recentKeyTimestamps.removeAll()
            showExitPrompt = false
            exitText = ""
            pressedKeys.removeAll()
        }
        .ignoresSafeArea()
        .onNSEvent(type: .keyDown) { event in
            guard isForcedBreakActive else { return false }
            
            // Record keystroke for mashing detection (skip if typing in exit prompt)
            if !showExitPrompt {
                recordKeystroke()
            }
            
            // Track pressed keys
            pressedKeys.insert(event.keyCode)
            
            // Check if Control+Command+Shift + E+S+C are all held
            if checkEmergencyShortcut(flags: event.modifierFlags) {
                pressedKeys.removeAll()
                timerManager.pause()
                return true
            }
            
            // Block Esc from dismissing the window
            if event.keyCode == 53 {
                return true
            }
            
            return false
        }
        .onNSEvent(type: .keyUp) { event in
            pressedKeys.remove(event.keyCode)
            return false
        }
        .onNSEvent(type: .flagsChanged) { event in
            // Also re-check on modifier changes while keys are held
            guard isForcedBreakActive else { return false }
            if checkEmergencyShortcut(flags: event.modifierFlags) {
                pressedKeys.removeAll()
                timerManager.pause()
                return true
            }
            return false
        }
        .onNSEvent(type: .leftMouseDown) { event in
            guard isForcedBreakActive else { return false }
            clickCount += 1
            if clickCount >= requiredClicks {
                shortcutUnlocked = true
            }
            return false
        }
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

/// Helper to handle global key down events inside SwiftUI (like Escape pressing)
struct NSEventView: NSViewRepresentable {
    let type: NSEvent.EventTypeMask
    let handler: (NSEvent) -> Bool

    func makeNSView(context: Context) -> EventTrackingView {
        let view = EventTrackingView()
        view.type = type
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: EventTrackingView, context: Context) {}
}

class EventTrackingView: NSView {
    var type: NSEvent.EventTypeMask = .keyDown
    var handler: ((NSEvent) -> Bool)?
    private var localMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: type) { [weak self] event in
                guard let self = self, let handler = self.handler else { return event }
                if handler(event) {
                    return nil // Consume event
                }
                return event
            }
            window?.makeFirstResponder(self)
        } else if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
}

extension View {
    func onNSEvent(type: NSEvent.EventTypeMask, perform: @escaping (NSEvent) -> Bool) -> some View {
        self.background(NSEventView(type: type, handler: perform))
    }
}

#Preview {
    Group {
        let settings = SettingsManager()
        CountdownOverlayView(timerManager: TimerManager(settings: settings))
    }
    .background(.black)
}
