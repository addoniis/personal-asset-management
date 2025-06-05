import Foundation

enum AdditionalInfoValue: Codable {
    case string(String)
    case integer(Int)
    case double(Double)
    // 可以添加更多你需要的型別
}

struct Asset: Codable, Identifiable {
    var id = UUID()
    var category: String
    var name: String
    var value: Double
    var additionalInfo: [String: AdditionalInfoValue] = [:]
}
