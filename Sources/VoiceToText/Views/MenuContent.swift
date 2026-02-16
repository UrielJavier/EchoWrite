import SwiftUI

struct MenuContent: View {
    let appDelegate: AppDelegate

    private var downloadedModels: [WhisperModel] {
        WhisperModel.allCases.filter { $0.isDownloaded }
    }

    var body: some View {
        @Bindable var state = appDelegate.appState
        let isBusy = state.isRecording || state.isTranscribing

        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: state.statusIcon)
                    .font(.title3)
                    .foregroundStyle(state.isRecording ? .red : .secondary)
                    .symbolEffect(.pulse, isActive: state.isRecording)
                if state.isDownloading, let model = state.downloadingModel {
                    Text("Downloading \(model.rawValue)...")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(state.downloadProgress * 100))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(state.status.rawValue).font(.headline)
                    Spacer()
                    if state.isRecording {
                        let secs = state.recordingSeconds
                        Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Live audio meter while recording
            if state.isRecording {
                AudioLevelMeter(level: state.audioLevel, threshold: state.liveSilenceThreshold)
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                if state.silenceCountdown > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.zzz")
                            .font(.caption2)
                        Text("Silence detected — stopping in \(state.silenceCountdown)s")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                    .transition(.opacity)
                }
            }

            if state.isDownloading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Downloading...").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Cancel") { appDelegate.cancelDownload() }
                        .font(.caption).buttonStyle(.plain).foregroundStyle(.red)
                }
            }

            Divider()

            // Mode picker
            VStack(alignment: .leading, spacing: 4) {
                Text("MODE").font(.caption2).foregroundStyle(.secondary)
                Picker("", selection: $state.mode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
            }
            .disabled(isBusy)

            // Model selector — only downloaded models
            let _ = state.modelListVersion
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("MODEL").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        appDelegate.openSettings(section: .models)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus.circle").font(.caption2)
                            Text("Manage").font(.caption2)
                        }
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                }

                if downloadedModels.isEmpty {
                    Button {
                        appDelegate.openSettings(section: .models)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Download a model")
                        }
                        .font(.callout).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(downloadedModels, id: \.self) { model in
                        ModelRow(
                            model: model,
                            isSelected: state.model == model && state.isModelLoaded,
                            isDownloading: false,
                            downloadProgress: 0,
                            chips: model.chips,
                            onSelect: {
                                Task { await appDelegate.loadModel(model) }
                            },
                            onDelete: nil
                        )
                    }
                }
            }
            .disabled(isBusy || state.isDownloading)

            if let error = state.lastError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(error).font(.caption)
                }
                .foregroundStyle(.red)
            }

            Divider()

            // Main action button
            if state.isLoadingModel {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading model...").font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            } else if !state.isModelLoaded && !state.isDownloading {
                Button { Task { await appDelegate.loadModel() } } label: {
                    HStack { Image(systemName: "arrow.down.circle"); Text("Load Model") }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).controlSize(.regular)
            } else {
                Button {
                    Task { await appDelegate.toggleRecording() }
                } label: {
                    HStack {
                        Image(systemName: state.isRecording ? "stop.fill" : "mic.fill")
                        Text(state.isRecording ? "Stop Recording" : "Start Recording")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).controlSize(.regular)
                .tint(state.isRecording ? .red : .accentColor)
                .disabled(state.isTranscribing || !state.isModelLoaded)
            }

            // Footer
            HStack(spacing: 8) {
                Text(state.hotkeyLabel).font(.caption).foregroundStyle(.tertiary)
                Spacer()

                Button { appDelegate.openHistory() } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }.buttonStyle(.bordered).controlSize(.small)

                Button { appDelegate.openSettings() } label: {
                    Image(systemName: "gear")
                }.buttonStyle(.bordered).controlSize(.small)

                Button { NSApplication.shared.terminate(nil) } label: {
                    Image(systemName: "power")
                }.buttonStyle(.bordered).controlSize(.small)
            }
        }
        .padding()
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.2), value: state.isRecording)
        .animation(.easeInOut(duration: 0.2), value: state.silenceCountdown)
        .onChange(of: state.mode) { appDelegate.saveSettings() }
        .onChange(of: state.model) { appDelegate.saveSettings() }
    }
}
