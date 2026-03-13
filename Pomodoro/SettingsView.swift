import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsManager
    @State private var updateManager = UpdateManager()
    var onDurationChange: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("⚙️ Settings")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // Duration Settings
            VStack(spacing: 12) {
                DurationRow(
                    icon: "🍅",
                    label: "Work",
                    value: $settings.workDuration,
                    range: 1...60,
                    onChange: onDurationChange
                )
                
                DurationRow(
                    icon: "☕️",
                    label: "Short\nBreak",
                    value: $settings.shortBreakDuration,
                    range: 1...30,
                    onChange: onDurationChange
                )
                
                DurationRow(
                    icon: "🌴",
                    label: "Long\nBreak",
                    value: $settings.longBreakDuration,
                    range: 1...30,
                    onChange: onDurationChange
                )
            }
            
            // Reset Button
            Button {
                settings.resetToDefaults()
                onDurationChange()
            } label: {
                Text("Reset to Defaults")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            
            Divider()
            
            // Check for Updates Section
            VStack {
                if updateManager.isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else if updateManager.isDownloading {
                    ProgressView(value: updateManager.downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 150)
                    Text("Downloading... \(Int(updateManager.downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    switch updateManager.updateStatus {
                    case .idle:
                        updateButton(title: "Check for Updates", icon: "arrow.triangle.2.circlepath") {
                            updateManager.checkForUpdates()
                        }
                    case .upToDate:
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Up to date")
                                .font(.caption)
                        }
                    case .updateAvailable(let version, let asset):
                        VStack(spacing: 4) {
                            Text("Version \(version) available!")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            updateButton(title: "Download & Install", icon: "arrow.down.circle") {
                                updateManager.downloadAndOpenUpdate(asset: asset)
                            }
                        }
                    case .error(let message):
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        updateButton(title: "Try Again", icon: "arrow.triangle.2.circlepath") {
                            updateManager.checkForUpdates()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 215)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func updateButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.secondary.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

struct DurationRow: View {
    let icon: String
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var onChange: () -> Void
    
    var body: some View {
        HStack {
            Text(icon)
            Text(label)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize()
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                        onChange()
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                Text("\(value) min")
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 50)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                        onChange()
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: SettingsManager(), onDurationChange: {})
}
