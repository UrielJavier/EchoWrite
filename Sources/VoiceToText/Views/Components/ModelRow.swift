import SwiftUI

struct ModelRow: View {
    let model: WhisperModel
    let isSelected: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let chips: [WhisperModel.ModelChip]
    let onSelect: () -> Void
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .font(.callout).padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(model.rawValue.capitalized).font(.callout)
                            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                                Text(chip.text).font(.caption2)
                                    .padding(.horizontal, 4).padding(.vertical, 1)
                                    .background(chip.style.color.opacity(0.15))
                                    .foregroundStyle(chip.style.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            Spacer()
                            if isDownloading {
                                ProgressView(value: downloadProgress).frame(width: 40)
                                Text("\(Int(downloadProgress * 100))%").font(.caption2).foregroundStyle(.secondary)
                            } else if !model.isDownloaded {
                                Image(systemName: "arrow.down.circle").foregroundStyle(.secondary).font(.caption)
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete downloaded model")
            }
        }
    }
}
