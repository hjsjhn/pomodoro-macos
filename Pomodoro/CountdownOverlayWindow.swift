import AppKit
import SwiftUI

/// Manages the fullscreen countdown overlay window
class CountdownOverlayWindow {
    private var window: NSWindow?
    
    /// Show the countdown overlay on all screens
    func show(timerManager: TimerManager) {
        // If window already exists, it will automatically update because
        // NSHostingView is bound to the @Bindable TimerManager. We just need to ensure it's visible.
        if let window = window {
            window.orderFrontRegardless()
            return
        }
        
        // Get the main screen bounds
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Create a borderless, transparent window
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver  // Above everything
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        // Enable mouse events so buttons can be clicked
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set the SwiftUI content
        window.contentView = NSHostingView(rootView: CountdownOverlayView(timerManager: timerManager))
        
        // Show the window
        window.orderFrontRegardless()
        
        self.window = window
    }
    
    /// Update the countdown number
    func updateContent(timerManager: TimerManager) {
        // No longer needed because the root view is already observing TimerManager natively.
        // Re-creating the NSHostingView on every tick was causing the UI to flash and reset its state.
    }
    
    /// Hide and release the overlay window
    func hide() {
        window?.orderOut(nil)
        window = nil
    }
    
    /// Check if overlay is currently visible
    var isVisible: Bool {
        return window != nil
    }
}
