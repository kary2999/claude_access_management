import SwiftUI

enum Theme {
    static let cardBG = Color(nsColor: .controlBackgroundColor)
    static let subtleBorder = Color.secondary.opacity(0.15)
    static let accent = Color.accentColor
}

struct Card<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder _ content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.cardBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title3.bold())
            if let s = subtitle {
                Text(s).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

struct Chip: View {
    let label: String
    let systemImage: String?
    let active: Bool
    let color: Color
    let action: () -> Void

    init(_ label: String, systemImage: String? = nil, active: Bool, color: Color = .accentColor, action: @escaping () -> Void) {
        self.label = label; self.systemImage = systemImage; self.active = active; self.color = color; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let s = systemImage { Image(systemName: s) }
                Text(label).fontWeight(active ? .semibold : .regular)
            }
            .font(.caption)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(active ? color.opacity(0.22) : Color.secondary.opacity(0.08))
            )
            .foregroundColor(active ? color : .secondary)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
