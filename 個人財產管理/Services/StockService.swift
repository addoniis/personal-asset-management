import Foundation
import Combine

class StockService: ObservableObject {
    static let shared = StockService()

    @Published var usdExchangeRate: Double = 0.0
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 每5分鐘更新一次匯率
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchUSDExchangeRate()
            }
            .store(in: &cancellables)

        fetchUSDExchangeRate()
    }

    // 獲取台股即時價格
    func fetchTWStockPrice(symbol: String) async throws -> Double {
        // 使用 TWSE API 獲取台股價格
        let urlString = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_\(symbol).tw"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let msgArray = json?["msgArray"] as? [[String: Any]],
              let firstStock = msgArray.first,
              let price = firstStock["z"] as? String,
              let priceDouble = Double(price) else {
            throw NSError(domain: "StockService", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法獲取股票價格"])
        }

        return priceDouble
    }

    // 獲取美股即時價格
    func fetchUSStockPrice(symbol: String) async throws -> Double {
        // 使用 Alpha Vantage API 獲取美股價格
        let apiKey = "YOUR_ALPHA_VANTAGE_API_KEY" // 需要替換為實際的 API key
        let urlString = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let globalQuote = json?["Global Quote"] as? [String: Any],
              let priceString = globalQuote["05. price"] as? String,
              let price = Double(priceString) else {
            throw NSError(domain: "StockService", code: 2, userInfo: [NSLocalizedDescriptionKey: "無法獲取股票價格"])
        }

        return price
    }

    // 獲取美元匯率
    private func fetchUSDExchangeRate() {
        // 使用台灣銀行匯率 API
        guard let url = URL(string: "https://rate.bot.com.tw/xrt/flcsv/0/day") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> Double in
                let csvString = String(data: data, encoding: .utf8) ?? ""
                let rows = csvString.components(separatedBy: "\n")
                guard rows.count > 1 else { return 0.0 }

                let usdRow = rows.first { $0.contains("USD") }
                guard let usdRow = usdRow else { return 0.0 }

                let columns = usdRow.components(separatedBy: ",")
                guard columns.count > 2 else { return 0.0 }

                return Double(columns[2]) ?? 0.0
            }
            .replaceError(with: 0.0)
            .receive(on: DispatchQueue.main)
            .assign(to: \.usdExchangeRate, on: self)
            .store(in: &cancellables)
    }
}

// 股票資訊模型
struct StockInfo {
    let symbol: String
    let shares: Int
    let currentPrice: Double
    let currency: Currency

    enum Currency: String {
        case TWD = "TWD"
        case USD = "USD"
    }

    var marketValue: Double {
        Double(shares) * currentPrice
    }

    var marketValueInTWD: Double {
        switch currency {
        case .TWD:
            return marketValue
        case .USD:
            return marketValue * StockService.shared.usdExchangeRate
        }
    }
}
