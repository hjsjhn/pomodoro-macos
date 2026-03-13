import Foundation
import AppKit

/// Represents the current status of the update check
enum UpdateStatus: Equatable {
    case idle
    case upToDate(String)
    case updateAvailable(version: String, asset: GitHubAsset)
    case error(String)
}

/// Represents a GitHub Release asset
struct GitHubAsset: Decodable, Equatable {
    let name: String
    let browser_download_url: URL
}

/// Represents a GitHub Release
struct GitHubRelease: Decodable {
    let tag_name: String
    let assets: [GitHubAsset]
}

/// Manages checking for and downloading updates from GitHub Releases
@Observable
class UpdateManager: NSObject, URLSessionDownloadDelegate {
    
    // MARK: - Properties
    
    var isChecking: Bool = false
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    var updateStatus: UpdateStatus = .idle
    
    private let repoOwner = "hjsjhn"
    private let repoName = "pomodoro-macos"
    
    private var downloadTask: URLSessionDownloadTask?
    
    @ObservationIgnored
    private var session: URLSession!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    // MARK: - Actions
    
    /// Checks GitHub for the latest release (including pre-releases)
    func checkForUpdates() {
        guard !isChecking else { return }
        
        isChecking = true
        updateStatus = .idle
        
        // Fetch all releases (this includes betas) instead of just /latest
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            finishCheck(with: .error("Invalid URL"))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.finishCheck(with: .error(error.localizedDescription))
                return
            }
            
            guard let data = data else {
                self.finishCheck(with: .error("No data received from GitHub"))
                return
            }
            
            do {
                let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
                
                // Get the very first release in the array (most recent by date)
                guard let latestRelease = releases.first else {
                    self.finishCheck(with: .error("No releases found"))
                    return
                }
                
                // Compare versions
                self.compareVersions(latestRelease: latestRelease)
                
            } catch {
                self.finishCheck(with: .error("Failed to parse GitHub response: \(error.localizedDescription)"))
            }
        }.resume()
    }
    
    /// Starts downloading the DMG asset and will open it upon completion
    func downloadAndOpenUpdate(asset: GitHubAsset) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        
        downloadTask = session.downloadTask(with: asset.browser_download_url)
        downloadTask?.resume()
    }
    
    /// Cancels an ongoing download
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0.0
    }
    
    // MARK: - Private Methods
    
    private func finishCheck(with status: UpdateStatus) {
        DispatchQueue.main.async {
            self.updateStatus = status
            self.isChecking = false
        }
    }
    
    private func compareVersions(latestRelease: GitHubRelease) {
        let latestVersion = latestRelease.tag_name.replacingOccurrences(of: "v", with: "")
        
        // Find the .dmg asset
        guard let dmgAsset = latestRelease.assets.first(where: { $0.name.hasSuffix(".dmg") }) else {
            finishCheck(with: .error("No .dmg asset found in release \(latestVersion)"))
            return
        }
        
        // Get current bundle version (MARKETING_VERSION)
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            finishCheck(with: .error("Could not read current app version"))
            return
        }
        
        // Compare Logic
        if isVersionGreater(latest: latestVersion, current: currentVersion) {
            finishCheck(with: .updateAvailable(version: latestVersion, asset: dmgAsset))
        } else {
            finishCheck(with: .upToDate(currentVersion))
        }
    }
    
    private func isVersionGreater(latest: String, current: String) -> Bool {
        let latestParts = latest.split(separator: "-")
        let currentParts = current.split(separator: "-")
        
        let latestBase = String(latestParts.first ?? "")
        let currentBase = String(currentParts.first ?? "")
        
        if latestBase.compare(currentBase, options: .numeric) == .orderedDescending {
            return true
        } else if latestBase == currentBase {
            let latestHasPre = latestParts.count > 1
            let currentHasPre = currentParts.count > 1
            
            if !latestHasPre && currentHasPre { return true }
            if latestHasPre && !currentHasPre { return false }
            if latestHasPre && currentHasPre {
                return String(latestParts[1]).compare(String(currentParts[1]), options: .numeric) == .orderedDescending
            }
        }
        return false
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.downloadProgress = progress
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file synchronously before URLSession deletes the temp file
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let originalFileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "PomodoroUpdate.dmg"
            let destinationURL = tempDir.appendingPathComponent(originalFileName)
            
            // If a file with the same name exists, remove it first
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            Task { @MainActor in
                // Open the DMG file automatically
                NSWorkspace.shared.open(destinationURL)
                self.isDownloading = false
                self.downloadProgress = 1.0
            }
        } catch {
            Task { @MainActor in
                self.updateStatus = .error("Failed to save DMG: \(error.localizedDescription)")
                self.isDownloading = false
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                // Ignore cancellation errors
                return
            }
            Task { @MainActor in
                self.updateStatus = .error("Download failed: \(error.localizedDescription)")
                self.isDownloading = false
            }
        }
    }
}
