import SwiftUI

enum AssetCategory: String, CaseIterable, Identifiable, Codable {
    case cash = "現金"
    case stock = "股票"
    case fund = "基金"
    case insurance = "保險"
    case property = "房產"
    case mortgage = "房貸"
    case other = "其他"

    var id: String { self.rawValue }

    var displayName: String {
        return self.rawValue
    }

    var displayColor: Color {
        switch self {
        case .cash:
            return .blue
        case .stock:
            return .green
        case .fund:
            return .orange
        case .insurance:
            return .purple
        case .property:
            return .red
        case .mortgage:
            return .gray
        case .other:
            return .secondary
        }
    }

    var icon: String {
        switch self {
        case .cash:
            return "dollarsign.circle"
        case .stock:
            return "chart.line.uptrend.xyaxis"
        case .fund:
            return "chart.pie"
        case .insurance:
            return "shield"
        case .property:
            return "house"
        case .mortgage:
            return "banknote"
        case .other:
            return "ellipsis.circle"
        }
    }
}

// 擴展 AssetCategory 以支援資產分析
extension AssetCategory {
    // 判斷資產是否為負債
    var isLiability: Bool {
        switch self {
        case .mortgage:
            return true
        default:
            return false
        }
    }

    // 獲取資產類別的排序權重
    var sortWeight: Int {
        switch self {
        case .cash: return 0
        case .stock: return 1
        case .fund: return 2
        case .insurance: return 3
        case .property: return 4
        case .mortgage: return 5
        case .other: return 6
        }
    }
}

// 為 AssetCategory 添加顏色屬性
extension AssetCategory {
    var color: Color {
        switch self {
        case .cash:
            return .blue
        case .stock:
            return .green
        case .fund:
            return .orange
        case .property:
            return .purple
        case .insurance:
            return .red
        case .mortgage:
            return .brown
        case .other:
            return .gray
        }
    }
}
