import SwiftUI

enum RiskLevel: Int, Codable, CaseIterable, Identifiable {
    case l1 = 1, l2, l3, l4, l5
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .l1: return "L1 只读"
        case .l2: return "L2 网络读"
        case .l3: return "L3 写入/安装"
        case .l4: return "L4 网络写"
        case .l5: return "L5 破坏性"
        }
    }

    var color: Color {
        switch self {
        case .l1: return .green
        case .l2: return .mint
        case .l3: return .yellow
        case .l4: return .orange
        case .l5: return .red
        }
    }
}
