import SwiftUI

func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12, content: content)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator.opacity(0.4)))
}

func settingsRow(_ title: String, icon: String, trailing: String? = nil) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(width: 20)
        Text(title).font(.body)
        Spacer()
        if let trailing {
            Text(trailing)
                .font(.body.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }
}

func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.title2).fontWeight(.semibold)
        if let subtitle {
            Text(subtitle).font(.callout).foregroundStyle(.secondary)
        }
    }
    .padding(.bottom, 4)
}
