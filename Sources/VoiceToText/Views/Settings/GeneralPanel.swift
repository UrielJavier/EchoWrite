import ServiceManagement
import SwiftUI

struct GeneralPanel: View {
    @Bindable var state: AppState
    let onSave: () -> Void
    var onHotkeyChange: (() -> Void)?
    var onPauseHotkey: (() -> Void)?
    var onResumeHotkey: (() -> Void)?
    var onLoadModel: ((WhisperModel) -> Void)?
    var onUnloadModel: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("General", subtitle: "Language, output and shortcut preferences")

            settingsCard {
                settingsRow("Language", icon: "globe")
                Picker("", selection: $state.language) {
                    ForEach(Language.allCases, id: \.self) { Text($0.label).tag($0) }
                }.labelsHidden()

                Toggle(isOn: $state.translateToEnglish) {
                    settingsRow("Translate to English", icon: "character.book.closed")
                }
                .toggleStyle(.switch)
            }

            settingsCard {
                settingsRow("Output mode", icon: "text.cursor")
                Picker("", selection: $state.outputMode) {
                    ForEach(OutputMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).labelsHidden()
                Text("Type simulates keystrokes. Clipboard copies the text.")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            settingsCard {
                settingsRow("Shortcut", icon: "command")
                HotkeyRecorderButton(
                    keyCode: $state.hotkeyKeyCode,
                    modifiers: $state.hotkeyModifiers,
                    onStartRecording: { onPauseHotkey?() },
                    onStopRecording: { onResumeHotkey?(); onSave(); onHotkeyChange?() }
                )
            }

            settingsCard {
                Toggle(isOn: $state.notifyOnComplete) {
                    settingsRow("Notify on completion", icon: "bell")
                }
                .toggleStyle(.switch)
                Divider()
                Toggle(isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { v in try? v ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
                )) {
                    settingsRow("Launch at login", icon: "power")
                }
                .toggleStyle(.switch)
            }

            settingsCard {
                settingsRow("Memory", icon: "memorychip")
                if state.isLoadingModel {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Loading \(state.model.rawValue)...").font(.callout).foregroundStyle(.secondary)
                    }
                } else if state.isModelLoaded {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(state.model.rawValue) loaded").font(.callout)
                            Text("Using \(state.model.ramUsage) of RAM").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Unload") { onUnloadModel?() }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                } else {
                    HStack {
                        Text("No model in memory").font(.callout).foregroundStyle(.secondary)
                        Spacer()
                        Button("Load") { onLoadModel?(state.model) }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                }
                Text("Unloading frees RAM when you're not using transcription. Loading takes a few seconds.")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(24)
    }
}
