import AppKit
import Foundation

final class ModelDownloadManager {
    private let appState: AppState
    private var session: URLSession?
    private var task: Task<Void, Never>?
    private let onComplete: (WhisperModel) async -> Void

    init(appState: AppState, onComplete: @escaping (WhisperModel) async -> Void) {
        self.appState = appState
        self.onComplete = onComplete
    }

    func download(_ model: WhisperModel) {
        task = Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.appState.isDownloading = true
                self.appState.downloadProgress = 0
                self.appState.downloadingModel = model
                self.appState.lastError = nil
            }
            do {
                let dir = AudioConstants.modelsDirectory
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                let delegate = DownloadDelegate { [weak self] progress in
                    Task { @MainActor in self?.appState.downloadProgress = progress }
                }
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 30
                config.timeoutIntervalForResource = 600
                let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
                self.session = session
                let (tempURL, response) = try await session.download(from: model.downloadURL)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                try Task.checkCancellation()
                let dest = URL(fileURLWithPath: model.localPath)
                if FileManager.default.fileExists(atPath: model.localPath) {
                    try FileManager.default.removeItem(atPath: model.localPath)
                }
                try FileManager.default.moveItem(at: tempURL, to: dest)
                session.invalidateAndCancel()
                self.session = nil
                await MainActor.run {
                    self.appState.isDownloading = false
                    self.appState.downloadingModel = nil
                    self.appState.modelListVersion += 1
                    NSSound(named: "Glass")?.play()
                }
                await self.onComplete(model)
            } catch is CancellationError {
                self.cleanup(model)
                await MainActor.run {
                    self.appState.isDownloading = false
                    self.appState.downloadingModel = nil
                    self.appState.lastError = "Download cancelled"
                }
            } catch {
                self.cleanup(model)
                await MainActor.run {
                    self.appState.isDownloading = false
                    self.appState.downloadingModel = nil
                    self.appState.lastError = "Download failed: \(error.localizedDescription)"
                    self.appState.status = .error
                }
            }
        }
    }

    @MainActor
    func cancel() {
        let model = appState.downloadingModel
        session?.invalidateAndCancel()
        session = nil
        task?.cancel()
        task = nil
        if let model { try? FileManager.default.removeItem(atPath: model.localPath) }
        appState.isDownloading = false
        appState.downloadingModel = nil
        appState.downloadProgress = 0
        appState.lastError = "Download cancelled"
    }

    private func cleanup(_ model: WhisperModel) {
        session?.invalidateAndCancel()
        session = nil
        try? FileManager.default.removeItem(atPath: model.localPath)
    }
}

// MARK: - DownloadDelegate

final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let onProgress: (Double) -> Void
    private var lastReportedAt: CFAbsoluteTime = 0

    init(onProgress: @escaping (Double) -> Void) { self.onProgress = onProgress }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if progress >= 1.0 || now - lastReportedAt >= 0.1 {
            lastReportedAt = now
            onProgress(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {}
}
