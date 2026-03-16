import AppKit
import SwiftUI

/// A custom NSWindow that can receive keyboard focus even though it is borderless
class POMOOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

/// Manages the fullscreen countdown overlay window
class CountdownOverlayWindow {
    private var windows: [NSWindow] = []
    
    /// Show the countdown overlay on all screens
    func show(timerManager: TimerManager) {
        let currentScreens = NSScreen.screens
        
        // If screen count changed or we don't have windows yet, recreate them
        if windows.count != currentScreens.count {
            windows.forEach { $0.close() }
            windows.removeAll()
            
            for screen in currentScreens {
                // Create a borderless, transparent window
                let window = POMOOverlayWindow(
                    contentRect: screen.frame,
                    styleMask: [.borderless, .fullSizeContentView],
                    backing: .buffered,
                    defer: false,
                    screen: screen
                )
            
            window.level = .screenSaver  // Above everything
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            // Enable mouse events so buttons can be clicked
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.setFrame(screen.frame, display: true)
            print("POMODORO DEBUG: Created overlay window for screen: \(screen.frame)")
            
            // Set the SwiftUI content
            window.contentView = NSHostingView(rootView: CountdownOverlayView(timerManager: timerManager))
            
            // Show the window and force it to grab keyboard focus so TextField works
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            
            self.windows.append(window)
        }
        }
        
        // Always ensure all windows are visible and properly sized
        for (index, window) in windows.enumerated() {
            if index < currentScreens.count {
                let screen = currentScreens[index]
                window.setFrame(screen.frame, display: true)
            }
            window.orderFrontRegardless()
        }
    }
    
    /// Update the countdown number
    func updateContent(timerManager: TimerManager) {
        // No longer needed because the root view is already observing TimerManager natively.
        // Re-creating the NSHostingView on every tick was causing the UI to flash and reset its state.
    }
    
    /// Hide and release the overlay window
    func hide() {
        // AppKit/SwiftUI NSHostingView gets corrupted if we try to close the window
        // while it is still observing @Bindable timerManager.
        // Instead of destroying the window, we simply hide it from the screen.
        windows.forEach { $0.orderOut(nil) }
    }
    
    /// Check if overlay is currently visible
    var isVisible: Bool {
        return windows.first?.isVisible ?? false
    }
}
