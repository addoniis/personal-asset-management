import Foundation
import Combine

@globalActor actor StockServiceActor {
    static let shared = StockServiceActor()
}

@MainActor
class StockService: ObservableObject {
    static let shared = StockService()

    @Published var usdExchangeRate: Double = 31.0  // 預設匯率
    private var cancellables = Set<AnyCancellable>()
    private let yahooFinanceBaseURL = "https://query1.finance.yahoo.com/v8/finance/chart"
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0

    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        return request
    }

    // 獲取台股即時價格
    func fetchTWStockPrice(symbol: String) async throws -> Double {
        let formattedSymbol = symbol.hasSuffix(".TW") ? symbol : "\(symbol).TW"
        let urlString = "\(yahooFinanceBaseURL)/\(formattedSymbol)?interval=1d&range=1d"

        print("Fetching TW stock price from: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let request = createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("Response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(YahooFinanceResponse.self, from: data)

        guard let price = result.chart.result.first?.meta.regularMarketPrice else {
            throw NSError(domain: "StockService", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法解析股價"])
        }

        return price
    }

    // 獲取美股即時價格
    func fetchUSStockPrice(symbol: String) async throws -> Double {
        let urlString = "\(yahooFinanceBaseURL)/\(symbol)?interval=1d&range=1d"

        print("Fetching US stock price from: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let request = createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("Response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(YahooFinanceResponse.self, from: data)

        guard let price = result.chart.result.first?.meta.regularMarketPrice else {
            throw NSError(domain: "StockService", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法解析股價"])
        }

        return price
    }

    // 獲取美元匯率
    private func fetchUSDExchangeRate() {
        let urlString = "\(yahooFinanceBaseURL)/TWD=X?interval=1d&range=1d"
        guard let url = URL(string: urlString) else { return }

        let request = createRequest(url: url)

        Task { @MainActor in
            do {
                let (data, _) = try await URLSession.shared.data(for: request)

                let decoder = JSONDecoder()
                let result = try decoder.decode(YahooFinanceResponse.self, from: data)

                if let rate = result.chart.result.first?.meta.regularMarketPrice {
                    self.usdExchangeRate = rate  // 直接使用 TWD/USD 匯率
                }
            } catch {
                print("Error fetching exchange rate: \(error)")
            }
        }
    }

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
}

// 股票資訊模型
@MainActor
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
            let service = StockService.shared
            return marketValue * service.usdExchangeRate
        }
    }
}

// Yahoo Finance API 回應結構
struct YahooFinanceResponse: Codable {
    let chart: Chart

    struct Chart: Codable {
        let result: [Result]

        struct Result: Codable {
            let meta: Meta

            struct Meta: Codable {
                let regularMarketPrice: Double
            }
        }
    }
}
