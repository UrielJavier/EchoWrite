import SwiftUI

struct AboutPanel: View {
    @Bindable var state: AppState
    let onSave: () -> Void
    var onHotkeyChange: (() -> Void)?

    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("About")

            settingsCard {
                HStack(spacing: 12) {
                    Image(systemName: "mic.badge.xmark")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EchoWrite").font(.title3.weight(.semibold))
                        Text("Local speech-to-text for macOS")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Feedback & Issues

            settingsCard {
                settingsRow("Feedback & Issues", icon: "exclamationmark.bubble")
                Text("Found a bug or have a suggestion? Open an issue on GitHub.")
                    .font(.callout).foregroundStyle(.secondary)

                Link(destination: URL(string: "https://github.com/urieljavier/EchoWrite")!) {
                    linkRow("EchoWrite on GitHub")
                }
                Link(destination: URL(string: "https://github.com/urieljavier/EchoWrite/issues/new")!) {
                    linkRow("Report an issue")
                }
            }

            Spacer().frame(height: 8)

            // MARK: - Reset

            settingsCard {
                settingsRow("Reset", icon: "arrow.counterclockwise")
                Text("Restore all settings to their original values. This will not delete downloaded models or history.")
                    .font(.callout).foregroundStyle(.secondary)
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset all settings to defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .alert("Reset all settings?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        state.resetToDefaults()
                        onSave()
                        onHotkeyChange?()
                    }
                } message: {
                    Text("This will restore all settings to their default values. Downloaded models and history will not be affected.")
                }
            }
        }
        .padding(24)
    }

    private func linkRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "link").font(.system(size: 11))
            Text(text).font(.callout)
        }
    }
}
