import SwiftUI

struct ModelsPanel: View {
    @Bindable var state: AppState
    var onDownloadModel: ((WhisperModel) -> Void)?
    var onLoadModel: ((WhisperModel) -> Void)?
    var onCancelDownload: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Models", subtitle: "Download and manage Whisper speech recognition models")

            // Official benchmarks
            settingsCard {
                settingsRow("Official benchmarks", icon: "chart.bar")
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                    GridRow {
                        Text("Model").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Params").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Speed").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("WER").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Use case").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    Divider()
                    benchmarkRow("Tiny", "39 M", "~10x", "High", "Testing only")
                    benchmarkRow("Base", "74 M", "~7x", "Med-high", "Live streaming")
                    benchmarkRow("Small", "244 M", "~4x", "Medium", "General use")
                    benchmarkRow("Medium", "769 M", "~2x", "Low", "Batch / offline")
                    benchmarkRow("Large v3", "1550 M", "1x", "~7.4%", "Max accuracy")
                    benchmarkRow("Turbo", "809 M", "~8x", "~7.7%", "Best for batch")
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))

                Text("Speed relative to Large (1x). WER = Word Error Rate on mixed benchmarks (lower is better). Turbo achieves near-Large accuracy at 8x the speed by reducing decoder layers from 32 to 4.")
                    .font(.caption).foregroundStyle(.tertiary)

                Link(destination: URL(string: "https://github.com/openai/whisper#available-models-and-languages")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "link").font(.caption2)
                        Text("Full benchmark table on GitHub").font(.caption)
                    }
                }
            }

            // Quantization explanation
            settingsCard {
                settingsRow("Quantization", icon: "scalemass")
                Text("Models come in full precision and quantized variants. Quantization reduces size and RAM usage with minimal quality loss.")
                    .font(.callout).foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    GridRow {
                        Text("Variant").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Bits").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Size").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Quality").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text("Speed").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    Divider()
                    GridRow {
                        Text("Full").font(.caption)
                        Text("16").font(.caption).foregroundStyle(.secondary)
                        Text("100%").font(.caption).foregroundStyle(.secondary)
                        Text("100%").font(.caption).foregroundStyle(.green)
                        Text("Baseline").font(.caption).foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("Q8").font(.caption)
                        Text("8").font(.caption).foregroundStyle(.secondary)
                        Text("~55%").font(.caption).foregroundStyle(.secondary)
                        Text("~99.7%").font(.caption).foregroundStyle(.green)
                        Text("Faster").font(.caption).foregroundStyle(.blue)
                    }
                    GridRow {
                        Text("Q5").font(.caption)
                        Text("5").font(.caption).foregroundStyle(.secondary)
                        Text("~35–40%").font(.caption).foregroundStyle(.secondary)
                        Text("~99%").font(.caption).foregroundStyle(.green)
                        Text("Fastest").font(.caption).foregroundStyle(.blue)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))
            }

            // Models by family
            ForEach(WhisperModel.Family.allCases, id: \.self) { family in
                settingsCard {
                    Text(family.rawValue).font(.callout.weight(.semibold))
                    Divider()
                    ForEach(family.models, id: \.self) { model in
                        modelSettingsRow(model)
                        if model != family.models.last {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(24)
    }

    private func benchmarkRow(_ model: String, _ params: String, _ speed: String, _ wer: String, _ useCase: String) -> GridRow<some View> {
        GridRow {
            Text(model).font(.caption)
            Text(params).font(.caption).foregroundStyle(.secondary)
            Text(speed).font(.caption.monospacedDigit()).foregroundStyle(.blue)
            Text(wer).font(.caption).foregroundStyle(.secondary)
            Text(useCase).font(.caption).foregroundStyle(.tertiary)
        }
    }

    private func modelSettingsRow(_ model: WhisperModel) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.rawValue).font(.callout)
                    ForEach(Array(model.chips.enumerated()), id: \.offset) { _, chip in
                        Text(chip.text).font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(chip.style.color.opacity(0.15))
                            .foregroundStyle(chip.style.color)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                HStack(spacing: 3) {
                    Text("\(model.label) · RAM \(model.ramUsage)")
                        .font(.caption2).foregroundStyle(.tertiary)
                    if let note = model.quantizationNote {
                        Text("· \(note) quantized")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            let _ = state.modelListVersion
            if state.downloadingModel == model {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Button("Cancel") { onCancelDownload?() }
                        .font(.caption2).buttonStyle(.plain).foregroundStyle(.red)
                }
            } else if model.isDownloaded {
                if !(state.model == model && state.isModelLoaded) {
                    Button("Load") { onLoadModel?(model) }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button {
                        try? FileManager.default.removeItem(atPath: model.localPath)
                        state.modelListVersion += 1
                    } label: {
                        Image(systemName: "trash").font(.caption2)
                    }
                    .buttonStyle(.plain).foregroundStyle(.red.opacity(0.6))
                }
            } else {
                Button("Download") { onDownloadModel?(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
    }
}
