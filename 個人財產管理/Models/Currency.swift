import Foundation

enum Currency: String, CaseIterable, Codable, Identifiable {
    case twd = "TWD"
    case usd = "USD"
    case jpy = "JPY"
    case cny = "CNY"
    case eur = "EUR"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .twd: return "新台幣"
        case .usd: return "美元"
        case .jpy: return "日圓"
        case .cny: return "人民幣"
        case .eur: return "歐元"
        }
    }

    var symbol: String {
        switch self {
        case .twd: return "NT$"
        case .usd: return "$"
        case .jpy: return "¥"
        case .cny: return "¥"
        case .eur: return "€"
        }
    }

    var locale: String {
        switch self {
        case .twd: return "zh_TW"
        case .usd: return "en_US"
        case .jpy: return "ja_JP"
        case .cny: return "zh_CN"
        case .eur: return "de_DE"
        }
    }

    var exchangeRate: Double {
        // 這裡應該從外部服務獲取實時匯率，目前使用固定匯率作為示例
        switch self {
        case .twd: return 1.0
        case .usd: return 31.5
        case .jpy: return 0.21
        case .cny: return 4.3
        case .eur: return 33.8
        }
    }

    func format(_ value: Double, shouldRound: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: locale)

        if shouldRound {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            return formatter.string(from: NSNumber(value: floor(value))) ?? "\(symbol)0"
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? "\(symbol)0.00"
        }
    }

    func convertToTWD(_ value: Double) -> Double {
        return value * exchangeRate
    }

    func convertFromTWD(_ value: Double) -> Double {
        return value / exchangeRate
    }
}
