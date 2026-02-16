import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @Bindable var state: AppState
    var onSave: (() -> Void)?
    @State private var searchText = ""

    private var filtered: [TranscriptionEntry] {
        if searchText.isEmpty { return state.history }
        return state.history.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if state.history.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)
                    Text("No transcriptions yet")
                        .font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // Search and header
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption).foregroundStyle(.tertiary)
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.callout)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))

                    Text("\(filtered.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)

                    Button { exportHistory() } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    .help("Export all to file")

                    Button("Clear All") { state.history.removeAll(); onSave?() }
                        .font(.caption).buttonStyle(.plain).foregroundStyle(.red)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)

                Divider()

                List {
                    ForEach(filtered) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.text)
                                .font(.callout)
                                .textSelection(.enabled)
                                .lineLimit(4)
                            HStack {
                                Text(entry.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption2).foregroundStyle(.tertiary)
                                if let dur = entry.durationSeconds {
                                    Text("\(dur)s")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if let wc = entry.wordCount {
                                    Text("\(wc) words")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if let mode = entry.mode {
                                    Text(mode)
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if entry.wasTranslated == true {
                                    Image(systemName: "character.book.closed")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.text, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc").font(.caption)
                                }.buttonStyle(.plain).foregroundStyle(.secondary)

                                Button {
                                    state.history.removeAll { $0.id == entry.id }
                                    onSave?()
                                } label: {
                                    Image(systemName: "trash").font(.caption)
                                }.buttonStyle(.plain).foregroundStyle(.red.opacity(0.6))
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .onDelete { offsets in
                        // Map filtered indices back to state.history
                        let idsToDelete = offsets.map { filtered[$0].id }
                        state.history.removeAll { idsToDelete.contains($0.id) }
                        onSave?()
                    }
                }
            }
        }
    }

    private func exportHistory() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let content = state.history.enumerated().map { i, entry in
            "[\(formatter.string(from: entry.date))]\n\(entry.text)"
        }.joined(separator: "\n\n---\n\n")

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "transcriptions.txt"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
