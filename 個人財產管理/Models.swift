import Foundation
import SwiftUI

// MARK: - Models
struct Asset: Codable, Identifiable {
    var id = UUID()
    var category: AssetCategory
    var name: String
    var value: Double
    var currency: Currency = .twd  // 新增幣別屬性，預設為新台幣
    var note: String = ""
    var additionalInfo: [String: AdditionalInfoValue] = [:]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // 轉換為新台幣的值
    var valueInTWD: Double {
        currency.convertToTWD(value)
    }

    // 格式化後的金額字串
    var formattedValue: String {
        currency.format(value)
    }
}

// MARK: - Supporting Types
enum AdditionalInfoValue: Codable {
    case string(String)
    case integer(Int)
    case double(Double)

    // 便利访問器
    var string: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    var integer: Int? {
        if case .integer(let value) = self {
            return value
        }
        return nil
    }

    var double: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

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

    // Display value for UI
    var displayValue: String {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return "\(value)"
        case .double(let value):
            return String(format: "%.2f", value)
        }
    }
}
