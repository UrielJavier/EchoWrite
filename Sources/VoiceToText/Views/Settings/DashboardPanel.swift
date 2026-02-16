import SwiftUI

struct DashboardPanel: View {
    @Bindable var state: AppState
    var onSave: (() -> Void)?
    @State private var showResetAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Dashboard", subtitle: "Usage statistics")

            // 2x2 stat cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(
                    title: "Recorded",
                    value: formatMinutes(state.stats.totalMinutes),
                    icon: "mic.fill",
                    color: .red
                )
                statCard(
                    title: "Words",
                    value: "\(state.stats.totalWords)",
                    icon: "text.word.spacing",
                    color: .blue
                )
                statCard(
                    title: "Time Saved",
                    value: formatMinutes(state.stats.timeSavedMinutes),
                    icon: "clock.arrow.2.circlepath",
                    color: .green
                )
                statCard(
                    title: "Translations",
                    value: "\(state.stats.totalTranslations)",
                    icon: "character.book.closed",
                    color: .orange
                )
            }

            // Detail table
            settingsCard {
                settingsRow("Sessions", icon: "number", trailing: "\(state.stats.totalSessions)")
                Divider()
                settingsRow("Words dictated", icon: "text.word.spacing", trailing: "\(state.stats.totalWords)")
                Divider()
                settingsRow("Recording time", icon: "mic.fill", trailing: formatDuration(state.stats.totalSeconds))
                Divider()
                settingsRow("Translations", icon: "character.book.closed", trailing: "\(state.stats.totalTranslations)")
                Divider()
                settingsRow("Time saved", icon: "clock.arrow.2.circlepath", trailing: formatMinutes(state.stats.timeSavedMinutes))
            }

            Text("Time saved estimated vs typing at ~40 WPM.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            // Reset button
            HStack {
                Spacer()
                Button("Reset Statistics") { showResetAlert = true }
                    .foregroundStyle(.red)
                Spacer()
            }
            .alert("Reset Statistics", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    state.stats = TranscriptionStats()
                    onSave?()
                }
            } message: {
                Text("This will reset all accumulated statistics to zero. Your transcription history will not be affected.")
            }
        }
        .padding(24)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        settingsCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title2.monospacedDigit().bold())
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Double) -> String {
        if minutes < 1 {
            return String(format: "%.0fs", minutes * 60)
        } else if minutes < 60 {
            return String(format: "%.1fm", minutes)
        } else {
            let h = Int(minutes) / 60
            let m = Int(minutes) % 60
            return "\(h)h \(m)m"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m \(seconds % 60)s"
        } else {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            return "\(h)h \(m)m"
        }
    }
}
