import SwiftUI

struct SoundsPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Sounds", subtitle: "Audio feedback when recording starts and stops")

            settingsCard {
                SoundPicker(label: "Start", icon: "play.circle", selection: $state.startSound)
                Divider()
                SoundPicker(label: "Stop", icon: "stop.circle", selection: $state.stopSound)
            }

            Text("Set to None to disable sound feedback.")
                .font(.caption).foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
        }
        .padding(24)
    }
}
