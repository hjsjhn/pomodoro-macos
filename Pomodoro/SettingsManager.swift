import Foundation

/// Manages user preferences for timer durations
@Observable
class SettingsManager {
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let workDuration = "workDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let isForcedBreakEnabled = "isForcedBreakEnabled"
    }
    
    // MARK: - Default Values
    private enum Defaults {
        static let workDuration: Int = 25
        static let shortBreakDuration: Int = 5
        static let longBreakDuration: Int = 15
        static let isForcedBreakEnabled: Bool = false
    }
    
    // MARK: - Properties (in minutes)
    
    /// Work session duration in minutes
    var workDuration: Int {
        didSet { UserDefaults.standard.set(workDuration, forKey: Keys.workDuration) }
    }
    
    /// Short break duration in minutes
    var shortBreakDuration: Int {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: Keys.shortBreakDuration) }
    }
    
    /// Long break duration in minutes
    var longBreakDuration: Int {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: Keys.longBreakDuration) }
    }
    
    /// Whether to force breaks and bypass the prompt
    var isForcedBreakEnabled: Bool {
        didSet { UserDefaults.standard.set(isForcedBreakEnabled, forKey: Keys.isForcedBreakEnabled) }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load from UserDefaults or use defaults
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: Keys.workDuration) != nil {
            self.workDuration = defaults.integer(forKey: Keys.workDuration)
        } else {
            self.workDuration = Defaults.workDuration
        }
        
        if defaults.object(forKey: Keys.shortBreakDuration) != nil {
            self.shortBreakDuration = defaults.integer(forKey: Keys.shortBreakDuration)
        } else {
            self.shortBreakDuration = Defaults.shortBreakDuration
        }
        
        if defaults.object(forKey: Keys.longBreakDuration) != nil {
            self.longBreakDuration = defaults.integer(forKey: Keys.longBreakDuration)
        } else {
            self.longBreakDuration = Defaults.longBreakDuration
        }
        
        if defaults.object(forKey: Keys.isForcedBreakEnabled) != nil {
            self.isForcedBreakEnabled = defaults.bool(forKey: Keys.isForcedBreakEnabled)
        } else {
            self.isForcedBreakEnabled = Defaults.isForcedBreakEnabled
        }
    }
    
    // MARK: - Methods
    
    /// Get duration in seconds for a session type
    func duration(for session: SessionType) -> TimeInterval {
        switch session {
        case .work:
            return TimeInterval(workDuration * 60)
        case .shortBreak:
            return TimeInterval(shortBreakDuration * 60)
        case .longBreak:
            return TimeInterval(longBreakDuration * 60)
        }
    }
    
    /// Reset all durations to defaults
    func resetToDefaults() {
        workDuration = Defaults.workDuration
        shortBreakDuration = Defaults.shortBreakDuration
        longBreakDuration = Defaults.longBreakDuration
        isForcedBreakEnabled = Defaults.isForcedBreakEnabled
    }
}
