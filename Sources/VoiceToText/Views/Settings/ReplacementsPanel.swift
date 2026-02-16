import SwiftUI

struct ReplacementsPanel: View {
    @Bindable var state: AppState
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Replacements", subtitle: "Text substitutions applied after each transcription. Case insensitive.")

            settingsCard {
                // Header
                HStack(spacing: 0) {
                    Text("Find").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Replace with").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(width: 52)
                }
                .padding(.horizontal, 4)

                Divider()

                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(state.replacementRules) { rule in
                            HStack(spacing: 8) {
                                TextField("text to find", text: ruleBinding(for: rule.id, keyPath: \.find))
                                    .textFieldStyle(.plain)
                                    .font(.callout)
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary.opacity(0.4)))

                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                TextField("replacement", text: ruleBinding(for: rule.id, keyPath: \.replace))
                                    .textFieldStyle(.plain)
                                    .font(.callout)
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary.opacity(0.4)))

                                Toggle("", isOn: ruleBinding(for: rule.id, keyPath: \.enabled))
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                    .labelsHidden()

                                Button {
                                    state.replacementRules.removeAll { $0.id == rule.id }
                                    onSave()
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.callout)
                                        .foregroundStyle(.red.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(minHeight: 100, maxHeight: 300)

                Divider()

                Button {
                    state.replacementRules.append(ReplacementRule(find: "", replace: ""))
                    onSave()
                } label: {
                    Label("Add rule", systemImage: "plus.circle")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            Text("\(state.replacementRules.filter { $0.enabled }.count) active rules")
                .font(.caption).foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
        }
        .padding(24)
        .onChange(of: state.replacementRules) { onSave() }
    }

    private func ruleBinding<T>(for id: UUID, keyPath: WritableKeyPath<ReplacementRule, T>) -> Binding<T> {
        Binding(
            get: {
                state.replacementRules.first { $0.id == id }?[keyPath: keyPath]
                    ?? ReplacementRule(find: "", replace: "")[keyPath: keyPath]
            },
            set: { newValue in
                if let index = state.replacementRules.firstIndex(where: { $0.id == id }) {
                    state.replacementRules[index][keyPath: keyPath] = newValue
                }
            }
        )
    }
}
