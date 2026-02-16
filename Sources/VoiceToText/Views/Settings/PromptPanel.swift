import SwiftUI

struct PromptPanel: View {
    @Bindable var state: AppState
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Prompt", subtitle: "Guide the transcription with context. All fields are optional — fill only what you need.")

            promptField(
                "Context", icon: "doc.text",
                placeholder: "e.g. Technical meeting about iOS development with SwiftUI",
                text: $state.promptContext
            )

            promptField(
                "Vocabulary", icon: "character.textbox",
                placeholder: "e.g. Whisper, Xcode, SwiftUI, Kubernetes",
                text: $state.promptVocabulary
            )

            promptField(
                "Style & Tone", icon: "theatermasks",
                placeholder: "e.g. Formal tone, complete sentences, third person",
                text: $state.promptStyle
            )

            promptField(
                "Punctuation", icon: "textformat.abc",
                placeholder: "e.g. Use commas, periods and question marks. No ellipsis",
                text: $state.promptPunctuation
            )

            promptField(
                "Instructions", icon: "plus.bubble",
                placeholder: "e.g. Ignore background noise. Short paragraphs",
                text: $state.promptInstructions
            )

            // Preview
            let composed = state.composedPrompt
            if !composed.isEmpty {
                settingsCard {
                    HStack(spacing: 8) {
                        Image(systemName: "eye")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text("Preview").font(.callout.weight(.medium))
                        Spacer()
                        Button {
                            state.promptContext = ""
                            state.promptVocabulary = ""
                            state.promptStyle = ""
                            state.promptPunctuation = ""
                            state.promptInstructions = ""
                        } label: {
                            Label("Clear all", systemImage: "xmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    Text(composed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))
                }
            }
        }
        .padding(24)
    }

    private func promptField(
        _ title: String, icon: String, placeholder: String,
        text: Binding<String>, axis: Axis = .vertical
    ) -> some View {
        settingsCard {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text(title).font(.callout.weight(.medium))
            }
            TextField(placeholder, text: text, axis: axis)
                .textFieldStyle(.plain)
                .font(.callout)
                .lineLimit(1...4)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
                .onChange(of: text.wrappedValue) { onSave() }
        }
    }
}
