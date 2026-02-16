import SwiftUI

struct RecordingPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Recording", subtitle: "Audio tuning for both Live and Batch modes. Changes apply on the next session.")

            settingsCard {
                settingsRow("Chunk interval", icon: "clock.arrow.2.circlepath",
                            trailing: String(format: "%.1fs", state.liveChunkInterval))
                Slider(value: $state.liveChunkInterval, in: 1...5, step: 0.5)
                    .tint(.accentColor)
                Text("How often audio is sent to transcribe. Shorter = faster but more CPU.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                settingsRow("Audio overlap", icon: "waveform.path",
                            trailing: "\(state.liveOverlapMs)ms")
                Slider(value: Binding(
                    get: { Double(state.liveOverlapMs) },
                    set: { state.liveOverlapMs = Int($0) }
                ), in: 0...1000, step: 100)
                    .tint(.accentColor)
                Text("Audio kept from the previous chunk to avoid cutting words at boundaries.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                settingsRow("Silence threshold", icon: "waveform.badge.minus",
                            trailing: String(format: "%.4f", state.liveSilenceThreshold))

                AudioLevelMeter(level: state.audioLevel, threshold: state.liveSilenceThreshold)
                    .frame(height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Slider(value: $state.liveSilenceThreshold, in: 0.0005...0.01, step: 0.0005)
                    .tint(.accentColor)
                Text("The bar shows your mic level in real time. The red line marks the silence threshold.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                settingsRow("Silence timeout", icon: "timer",
                            trailing: String(format: "%.0fs", state.liveSilenceTimeout))
                Slider(value: $state.liveSilenceTimeout, in: 4...60, step: 2)
                    .tint(.accentColor)
                Text("Seconds of continuous silence before auto-stopping.")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(24)
    }
}
