import Foundation

// MARK: - Enums
enum AssetCategory: String, CaseIterable, Codable {
    case cash = "現金"
    case stock = "股票"
    case fund = "基金"
    case insurance = "儲蓄險"
    case property = "房產"
    case mortgage = "房貸"
    case other = "其他"

    var icon: String {
        switch self {
        case .cash: return "dollarsign.circle"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .fund: return "chart.pie"
        case .insurance: return "shield"
        case .property: return "house"
        case .mortgage: return "banknote"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Models
struct Asset: Codable, Identifiable {
    var id = UUID()
    var category: AssetCategory
    var name: String
    var value: Double
    var additionalInfo: [String: AdditionalInfoValue] = [:]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Supporting Types
enum AdditionalInfoValue: Codable {
    case string(String)
    case integer(Int)
    case double(Double)

    // Custom coding keys for type safety
    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .integer(let value):
            try container.encode("integer", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "integer":
            let value = try container.decode(Int.self, forKey: .value)
            self = .integer(value)
        case "double":
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
}
