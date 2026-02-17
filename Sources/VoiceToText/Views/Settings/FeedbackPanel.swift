import SwiftUI

struct FeedbackPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Feedback", subtitle: "Audio and visual feedback during recording")

            settingsCard {
                SoundPicker(label: "Start", icon: "play.circle", selection: $state.startSound)
                Divider()
                SoundPicker(label: "Stop", icon: "stop.circle", selection: $state.stopSound)
                Text("Set to None to disable sound feedback.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                Toggle(isOn: $state.showFloatingWindow) {
                    settingsRow("Show floating window while recording", icon: "rectangle.on.rectangle")
                }
                .toggleStyle(.switch)
                Text("Displays a small always-on-top overlay with timer and audio waveform while recording.")
                    .font(.caption).foregroundStyle(.tertiary)

                Divider()

                Toggle(isOn: $state.notifyOnComplete) {
                    settingsRow("Notify on completion", icon: "bell")
                }
                .toggleStyle(.switch)
                Text("Shows a system notification when transcription finishes.")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(24)
    }
}
