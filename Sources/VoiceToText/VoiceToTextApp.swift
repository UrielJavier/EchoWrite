import SwiftUI

@main
struct VoiceToTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(appDelegate: appDelegate)
        } label: {
            let state = appDelegate.appState
            if state.isDownloading {
                Image(systemName: "arrow.down.circle")
                Text("\(Int(state.downloadProgress * 100))%")
            } else if state.isRecording {
                MenuBarEqualizer(level: state.audioLevel)
                let secs = state.recordingSeconds
                Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
            } else {
                Image(systemName: state.statusIcon)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
