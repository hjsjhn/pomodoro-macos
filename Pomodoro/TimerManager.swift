import Foundation
import Combine
import AppKit

/// Manages the Pomodoro timer state and logic
@Observable
class TimerManager {
    // MARK: - Properties
    
    /// Current time remaining in seconds
    var timeRemaining: TimeInterval
    
    /// Current session type
    var currentSession: SessionType = .work
    
    /// Whether the timer is currently running
    var isRunning: Bool = false
    
    /// Number of completed pomodoros in the current cycle
    var completedPomodoros: Int = 0
    
    /// Total pomodoros before a long break
    let pomodorosBeforeLongBreak: Int = 4
    
    /// Auto-mode: automatically start next session
    var isAutoMode: Bool = false
    
    /// Whether to show the countdown overlay (last 5 seconds or waiting for action/auto-transition)
    var showCountdownOverlay: Bool {
        if settings.isForcedBreakEnabled && currentSession != .work {
            return isRunning || isWaitingForAction // Always show during break if forced
        }
        return (isRunning && timeRemaining <= 5 && timeRemaining >= 0) || isWaitingForAction || (autoTransitionMessage != nil)
    }
    
    /// Current countdown number for overlay (3, 2, or 1)
    var countdownNumber: Int {
        return Int(ceil(timeRemaining))
    }
    
    var isWaitingForAction: Bool = false
    var autoTransitionMessage: String? = nil
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    let settings: SettingsManager
    
    // MARK: - Initialization
    
    init(settings: SettingsManager) {
        self.settings = settings
        self.timeRemaining = settings.duration(for: .work)
    }
    
    // MARK: - Overlay Actions
    
    func overlayActionContinue() {
        isWaitingForAction = false
        moveToNextSession()
        start()
    }
    
    func overlayActionPause() {
        isWaitingForAction = false
        moveToNextSession()
        // Does not start, remains paused
    }
    
    // MARK: - Computed Properties
    
    /// Formatted time string (MM:SS)
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Progress from 0.0 to 1.0
    var progress: Double {
        let total = settings.duration(for: currentSession)
        return (total - timeRemaining) / total
    }
    

    // MARK: - Timer Controls
    
    /// Start or resume the timer
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// Pause the timer
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    /// Toggle between start and pause
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    /// Reset the current session
    func reset() {
        pause()
        timeRemaining = settings.duration(for: currentSession)
    }
    
    /// Skip to the next session
    func skip() {
        pause()
        if currentSession == .work {
            completedPomodoros += 1
        }
        moveToNextSession()
        
        // Automatically start the next session if forced breaks are enabled
        if settings.isForcedBreakEnabled && currentSession != .work {
            start()
        }
    }
    
    /// Refresh duration from settings (call when settings change)
    func refreshDuration() {
        if !isRunning {
            timeRemaining = settings.duration(for: currentSession)
        }
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 0 {
                sessionCompleted()
            }
        }
    }
    
    private func sessionCompleted() {
        pause()
        
        // Update completed pomodoros if work session finished
        if currentSession == .work {
            completedPomodoros += 1
            
            if settings.isForcedBreakEnabled {
                moveToNextSession()
                start()
                return
            }
        }
        
        if isAutoMode {
            // Determine next session name for message
            var nextType: SessionType
            if currentSession == .work {
                if completedPomodoros > 0 && completedPomodoros % pomodorosBeforeLongBreak == 0 {
                    nextType = .longBreak
                } else {
                    nextType = .shortBreak
                }
            } else {
                nextType = .work
            }
            
            let message = nextType == .work ? "现在继续之前的工作" : "现在开始休息"
            autoTransitionMessage = message
            
            // Auto-start after a brief delay so the user reads the message
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self else { return }
                self.autoTransitionMessage = nil
                self.moveToNextSession()
                self.start()
            }
        } else {
            // Wait for user to interact with overlay buttons
            isWaitingForAction = true
        }
    }
    
    private func moveToNextSession() {
        switch currentSession {
        case .work:
            // Check if it's time for a long break
            if completedPomodoros > 0 && completedPomodoros % pomodorosBeforeLongBreak == 0 {
                currentSession = .longBreak
            } else {
                currentSession = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentSession = .work
        }
        
        timeRemaining = settings.duration(for: currentSession)
    }
    
    /// Reset everything to initial state
    func resetAll() {
        pause()
        completedPomodoros = 0
        currentSession = .work
        timeRemaining = settings.duration(for: currentSession)
    }
}
