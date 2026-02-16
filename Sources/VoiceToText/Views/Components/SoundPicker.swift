import SwiftUI

struct SoundPicker: View {
    let label: String
    var icon: String = "speaker.wave.2"
    @Binding var selection: SoundEffect

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label).font(.callout).frame(width: 40, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(SoundEffect.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.labelsHidden().controlSize(.small)
            Button { selection.play() } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .padding(4)
                    .background(Circle().fill(.secondary.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(selection == .none)
        }
    }
}
