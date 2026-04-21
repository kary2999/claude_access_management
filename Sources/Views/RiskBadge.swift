import SwiftUI

struct RiskBadge: View {
    let level: RiskLevel
    var body: some View {
        Text(level.label)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(level.color.opacity(0.2))
            .foregroundColor(level.color)
            .clipShape(Capsule())
    }
}
