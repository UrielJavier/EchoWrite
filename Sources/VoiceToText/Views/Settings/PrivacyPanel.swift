import SwiftUI

struct PrivacyPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Privacy", subtitle: "Permissions, data storage and trust chain")

            settingsCard {
                settingsRow("Permissions", icon: "lock.shield")
                Text("Everything runs locally on your Mac. No audio, text or data is ever sent to any server.")
                    .font(.callout).foregroundStyle(.secondary)

                Divider()

                permissionRow(
                    icon: "mic",
                    name: "Microphone",
                    reason: "Records your voice for local transcription. Audio is processed entirely on-device by whisper.cpp and discarded after transcription — it is never stored or transmitted.",
                    api: "AVCaptureDevice (AVFoundation)"
                )

                Divider()

                permissionRow(
                    icon: "accessibility",
                    name: "Accessibility",
                    reason: "Required for two features:",
                    details: [
                        ("keyboard", "Global hotkey — intercepts your shortcut (\(state.hotkeyLabel)) via CGEvent tap so it works in any app without the system beep."),
                        ("text.cursor", "Type mode — simulates keystrokes (CGEvent) to type the transcribed text at your cursor position. Not used in Clipboard mode."),
                    ],
                    api: "CGEvent.tapCreate / CGEvent (CoreGraphics)"
                )

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        Text("No network access required").font(.callout.weight(.medium))
                    }
                    Text("The app only connects to the internet when you explicitly download a model from Settings > Models. All transcription is offline.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }

            settingsCard {
                settingsRow("Data & Storage", icon: "folder.badge.gearshape")

                dataRow(
                    icon: "brain",
                    label: "Models",
                    path: "~/.voicetotext/models/",
                    detail: "Downloaded model files (binary weights, no code). You can delete them from Settings > Models."
                )

                Divider()

                dataRow(
                    icon: "gearshape",
                    label: "Settings",
                    path: "UserDefaults (standard)",
                    detail: "Preferences, prompt, replacement rules and history. Reset from About > Reset."
                )

                Text("No other files are created. No analytics, telemetry or crash reports are collected.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                settingsRow("Trust chain", icon: "checkmark.shield")
                VStack(alignment: .leading, spacing: 6) {
                    trustStep("1", "OpenAI trains and publishes the original Whisper models (open-source, MIT license)")
                    trustStep("2", "Georgi Gerganov (ggerganov) converts them to GGML format via whisper.cpp, the most used C/C++ inference engine for Whisper")
                    trustStep("3", "Models are hosted on HuggingFace and downloaded over HTTPS to ~/.voicetotext/models/")
                }

                Text("Model files are binary weights (numbers, no executable code). The source code of whisper.cpp is fully open and auditable.")
                    .font(.caption).foregroundStyle(.tertiary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Link(destination: URL(string: "https://github.com/ggml-org/whisper.cpp")!) {
                        linkRow("whisper.cpp on GitHub")
                    }
                    Link(destination: URL(string: "https://huggingface.co/ggerganov/whisper.cpp")!) {
                        linkRow("Models on HuggingFace")
                    }
                    Link(destination: URL(string: "https://github.com/openai/whisper")!) {
                        linkRow("OpenAI Whisper (MIT License)")
                    }
                    Link(destination: URL(string: "https://developer.apple.com/documentation/coregraphics/cgevent")!) {
                        linkRow("Apple CGEvent documentation")
                    }
                    Link(destination: URL(string: "https://developer.apple.com/documentation/avfoundation/avcapturedevice")!) {
                        linkRow("Apple AVCaptureDevice documentation")
                    }
                }
            }
        }
        .padding(24)
    }

    // MARK: - Helpers

    private func permissionRow(
        icon: String, name: String, reason: String,
        details: [(icon: String, text: String)]? = nil,
        api: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .frame(width: 20)
                Text(name).font(.callout.weight(.medium))
            }
            Text(reason).font(.caption).foregroundStyle(.secondary)
            if let details {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(details, id: \.icon) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .frame(width: 16)
                                .padding(.top, 2)
                            Text(item.text)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 4)
            }
            Text("API: \(api)")
                .font(.caption2).foregroundStyle(.quaternary)
        }
    }

    private func dataRow(icon: String, label: String, path: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text(label).font(.callout.weight(.medium))
            }
            Text(path)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
            Text(detail)
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func trustStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.secondary.opacity(0.5)))
            Text(text)
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    private func linkRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "link").font(.system(size: 11))
            Text(text).font(.callout)
        }
    }
}
