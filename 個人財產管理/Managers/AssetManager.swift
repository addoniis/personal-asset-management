import Foundation
import Combine
import SwiftUI
// import Models // Removed: Not needed for types within the same target
// import StorageManager // Removed: Not needed for types within the same target
// import StockService // Removed: Not needed for types within the same target
// import CSVImporter // Removed: Not needed for types within the same target

@MainActor
class AssetManager: ObservableObject {
    static let shared = AssetManager()
    private let storageManager = StorageManager.shared
    private let stockService = StockService.shared

    @Published private(set) var assets: [Asset] = []
    @Published private(set) var assetHistory: [AssetHistory] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private var cancellables = Set<AnyCancellable>()

    struct AssetHistory: Codable, Identifiable {
        let id: UUID
        let date: Date
        let totalValue: Double
        let growthRate: Double

        init(id: UUID = UUID(), date: Date, totalValue: Double, growthRate: Double) {
            self.id = id
            self.date = date
            self.totalValue = totalValue
            self.growthRate = growthRate
        }
    }

    var totalAssets: Double {
        let cashAssets = assets.filter { $0.category == .cash }.reduce(0) { $0 + $1.valueInTWD }  //現金資產
        let stockAssets = calculateStockTotalValue()  //股票資產
        let fundAssets = assets.filter { $0.category == .fund }.reduce(0) { $0 + $1.valueInTWD }  //基金資產
        let insuranceAssets = assets.filter { $0.category == .insurance }.reduce(0) { $0 + $1.valueInTWD } //保險資產
        let propertyValue = assets.filter { $0.category == .property }.reduce(0) { $0 + $1.valueInTWD } //房產資產
        let mortgageValue = assets.filter { $0.category == .mortgage }.reduce(0) { $0 + $1.valueInTWD } //房屋貸款
        let realEstateNetValue = propertyValue - mortgageValue  //房屋淨資產
        let otherAssets = assets.filter { $0.category == .other }.reduce(0) { $0 + $1.valueInTWD }  //其他

        return cashAssets + stockAssets + fundAssets + insuranceAssets + realEstateNetValue + otherAssets - mortgageValue
    }

    var totalCash: Double {
        assets.filter { $0.category == .cash }.reduce(0) { $0 + $1.valueInTWD }
    }

    var totalStocks: Double {
        calculateStockTotalValue()
    }

    var totalProperties: Double {
        assets.filter { $0.category == .property }.reduce(0) { $0 + $1.valueInTWD }
    }

    var totalInsurance: Double {
        assets.filter { $0.category == .insurance }.reduce(0) { $0 + $1.valueInTWD }
    }

    var assetsByCategory: [AssetCategory: Double] {
        var categorizedAssets: [AssetCategory: Double] = [
            .cash: 0,
            .stock: 0,
            .fund: 0,
            .insurance: 0,
            .property: 0,
            .mortgage: 0,
            .other: 0
        ]

        for asset in assets {
            if asset.category == .property {
                categorizedAssets[.property] = (categorizedAssets[.property] ?? 0) + asset.valueInTWD
            } else if asset.category == .mortgage {
                categorizedAssets[.mortgage] = (categorizedAssets[.mortgage] ?? 0) - asset.valueInTWD
            } else if asset.category == .stock {
                guard let shares = asset.additionalInfo["shares"]?.double,
                      let stockMarket = asset.additionalInfo["stockMarket"]?.string else {
                    categorizedAssets[.stock] = (categorizedAssets[.stock] ?? 0) + asset.valueInTWD
                    continue
                }

                let symbol = asset.name
                var currentPrice: Double?

                if stockMarket == "台股" {
                    let formattedSymbol = symbol.hasSuffix(".TW") ? symbol : "\(symbol).TW"
                    currentPrice = stockService.currentStockPrices[formattedSymbol]
                } else if stockMarket == "美股" {
                    currentPrice = stockService.currentStockPrices[symbol]
                }

                if let price = currentPrice {
                    let marketValue = price * shares
                    if asset.currency == .usd {
                        categorizedAssets[.stock] = (categorizedAssets[.stock] ?? 0) + (marketValue * stockService.usdExchangeRate)
                    } else {
                        categorizedAssets[.stock] = (categorizedAssets[.stock] ?? 0) + marketValue
                    }
                } else {
                    categorizedAssets[.stock] = (categorizedAssets[.stock] ?? 0) + asset.valueInTWD
                }
            } else {
                categorizedAssets[asset.category] = (categorizedAssets[asset.category] ?? 0) + asset.valueInTWD
            }
        }

        categorizedAssets.removeValue(forKey: .mortgage)

        return categorizedAssets
    }

    var monthlyGrowthRate: Double {
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        let lastMonthAssets = assetHistory.first { history in
            Calendar.current.isDate(history.date, equalTo: lastMonth, toGranularity: .month)
        }
        guard let lastMonthValue = lastMonthAssets?.totalValue, lastMonthValue > 0 else { return 0 }
        return ((totalAssets - lastMonthValue) / lastMonthValue) * 100
    }

    init() {
        Task {
            await loadAssets()
            await fetchRealtimeStockPrices()
        }
        loadHistory()
        stockService.$currentStockPrices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        stockService.$usdExchangeRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Operations
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        saveAssets()
        updateHistory()
        Task { await fetchRealtimeStockPrices() }
    }

    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            saveAssets()
            updateHistory()
            Task { await fetchRealtimeStockPrices() }
        }
    }

    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        saveAssets()
        updateHistory()
        Task { await fetchRealtimeStockPrices() }
    }

    // MARK: - Data Operations
    @MainActor
    func loadAssets() async {
        isLoading = true
        error = nil

        do {
            assets = try storageManager.loadAssets()
        } catch {
            self.error = error.localizedDescription
            assets = []
        }

        isLoading = false
    }


    @MainActor
    func fetchRealtimeStockPrices() async {
        for asset in assets.filter({ $0.category == .stock }) {
            // 修正 stockSymbol 的處理
            // 移除 asset.additionalInfo 後面的 "?"
            // 並使用 as? String 來安全地轉換為 String?
//            let stockSymbol = (asset.additionalInfo["symbol"] as? String) ?? asset.name
            let stockSymbol: String
            if let symbolValue = asset.additionalInfo["symbol"], let symbolString = symbolValue.string {
                stockSymbol = symbolString
            } else {
                stockSymbol = asset.name // 如果找不到或不是字串，則使用 asset.name 作為備用
                print("Warning: additionalInfo[\"symbol\"] is missing or not a string type for asset: \(asset.name)")
            }

            // 修正 isUSStock 的處理
            // 移除 asset.additionalInfo 後面的 "?"
            // 並使用 as? String 來安全地轉換為 String?
//            let isUSStock = (asset.additionalInfo["isUSStock"] as? String == "true")
            // 取得是否為美股 (isUSStock)

            // 使用 AdditionalInfoValue 的 .string 便利訪問器
            let isUSStock: Bool
            if let isUSStockValue = asset.additionalInfo["isUSStock"], let usStockString = isUSStockValue.string {
                isUSStock = (usStockString.lowercased() == "true") // 考慮大小寫不敏感
            } else {
                isUSStock = false // 如果找不到或不是字串 "true"，則預設為 false
                print("Warning: additionalInfo[\"isUSStock\"] is missing or not a string 'true' for asset: \(asset.name)")
            }

            do {
                let price = try await (isUSStock
                    ? stockService.fetchUSStockPrice(symbol: stockSymbol)
                    : stockService.fetchTWStockPrice(symbol: stockSymbol))
                
                // 你需要使用這個 price，例如更新 assetManager 中的資產
                // 假設你在 AssetManager 中有一個方法來更新資產的價格
                // assetManager.updateAssetPrice(symbol: stockSymbol, newPrice: price)
                
                print("Fetched price for \(stockSymbol): \(price)")
            } catch {
                print("Error fetching price for \(stockSymbol) in AssetManager: \(error)")
            }
        }
    }

    private func saveAssets() {
        do {
            try storageManager.saveAssets(assets)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadHistory() {
        assetHistory = storageManager.loadAssetHistory()
    }

    private func updateHistory() {
        let newHistory = AssetHistory(
            date: Date(),
            totalValue: totalAssets,
            growthRate: monthlyGrowthRate
        )
        assetHistory.append(newHistory)
        do {
            try storageManager.saveAssetHistory(assetHistory)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Filtering & Sorting
    func assets(for category: AssetCategory? = nil) -> [Asset] {
        guard let category = category else { return assets }
        return assets.filter { $0.category == category }
    }

    func totalValue(for category: AssetCategory? = nil) -> Double {
        if category == .stock {
            return totalStocks
        }
        guard let category = category else { return totalAssets }
        return assets(for: category).reduce(0) { $0 + $1.valueInTWD }
    }

    // MARK: - Backup & Restore
    func createBackup() throws -> URL {
        try storageManager.createBackup()
    }

    @MainActor
    func restoreFromBackup(at url: URL) async throws {
        try storageManager.restoreFromBackup(at: url)
        await loadAssets()
    }

    func getAssetHistory(for category: AssetCategory, months: Int) -> [AssetHistory] {
        let filtered = assetHistory.filter { history in
            guard let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
                return false
            }
            return history.date >= cutoffDate
        }
        return filtered.sorted { $0.date < $1.date }
    }

    func getGrowthRate(for category: AssetCategory) -> Double {
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        let currentValue = assetsByCategory[category] ?? 0

        let lastMonthAssets = assetHistory.first { history in
            Calendar.current.isDate(history.date, equalTo: lastMonth, toGranularity: .month)
        }
        guard let lastMonthValue = lastMonthAssets?.totalValue, lastMonthValue > 0 else { return 0 }

        return ((currentValue - lastMonthValue) / lastMonthValue) * 100
    }

    // MARK: - Analytics Methods
    func getAssetHistory(months: Int) -> [AssetHistory] {
        let filtered = assetHistory.filter { history in
            guard let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
                return false
            }
            return history.date >= cutoffDate
        }
        return filtered.sorted { $0.date < $1.date }
    }

    func getGrowthHistory(months: Int) -> [AssetHistory] {
        let history = getAssetHistory(months: months)
        guard !history.isEmpty else { return [] }

        var growthHistory: [AssetHistory] = []
        for i in 1..<history.count {
            let previousValue = history[i-1].totalValue
            let currentValue = history[i].totalValue
            let growthRate = previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0

            growthHistory.append(AssetHistory(
                date: history[i].date,
                totalValue: currentValue,
                growthRate: growthRate
            ))
        }
        return growthHistory
    }

    func importAssetsFromCSV(_ csvString: String) {
        // 清除現有資產
        assets.removeAll()

        // 導入新資產
        let importedAssets = CSVImporter.importAssets(from: csvString)
        assets.append(contentsOf: importedAssets)

        // 保存並通知更新
        saveAssets()
        updateHistory()
        objectWillChange.send()
    }

    func exportAssetsToCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        var csv = "類別,名稱,數量,建立於,備註\n"

        for asset in assets {
            var categoryStr: String
            var quantityStr: String
            var nameStr: String

            switch asset.category {
            case .cash:
                categoryStr = asset.category.displayName
                quantityStr = String(format: "%.0f", asset.value)
                nameStr = asset.name
                let currencyCode = asset.additionalInfo["currency"]?.string ?? "TWD"
                let existingNote = asset.note.isEmpty ? "" : asset.note + " "
                let noteWithCurrency = currencyCode == "TWD" ? asset.note : existingNote + currencyCode

                csv += "\(categoryStr),\(nameStr),\(quantityStr),\(dateFormatter.string(from: asset.createdAt)),\(noteWithCurrency)\n"
                continue

            case .stock:
                if let isUSStock = asset.additionalInfo["isUSStock"]?.string,
                   let shares = asset.additionalInfo["shares"]?.string,
                   let symbol = asset.additionalInfo["symbol"]?.string {
                    categoryStr = isUSStock == "true" ? "美國股票" : "台灣股票"
                    quantityStr = shares
                    nameStr = symbol
                } else {
                    continue
                }
                csv += "\(categoryStr),\(nameStr),\(quantityStr),\(dateFormatter.string(from: asset.createdAt)),\(asset.note)\n"
                continue

            default:
                categoryStr = asset.category.displayName
                quantityStr = String(format: "%.0f", asset.value)
                nameStr = asset.name
                csv += "\(categoryStr),\(nameStr),\(quantityStr),\(dateFormatter.string(from: asset.createdAt)),\(asset.note)\n"
            }
        }

        return csv
    }

    private func calculateStockTotalValue() -> Double {
        assets.filter { $0.category == .stock }.reduce(0) { total, asset in
            guard let shares = asset.additionalInfo["shares"]?.double,
                  let stockMarket = asset.additionalInfo["stockMarket"]?.string else {
                return total + asset.valueInTWD
            }

            let symbol = asset.name
            var currentPrice: Double?

            if stockMarket == "台股" {
                let formattedSymbol = symbol.hasSuffix(".TW") ? symbol : "\(symbol).TW"
                currentPrice = stockService.currentStockPrices[formattedSymbol]
            } else if stockMarket == "美股" {
                currentPrice = stockService.currentStockPrices[symbol]
            }

            if let price = currentPrice {
                let marketValue = price * shares
                if asset.currency == .usd {
                    return total + (marketValue * stockService.usdExchangeRate)
                } else {
                    return total + marketValue
                }
            } else {
                return total + asset.valueInTWD
            }
        }
    }
    // MARK: - loadEmbeddedSampleAssets
    func loadEmbeddedSampleAssets() async {
        let filename = "sample_assets"
        let fileExtension = "csv"

        guard let bundlePath = Bundle.main.path(forResource: filename, ofType: fileExtension) else {
            print("DEBUG: Bundle.main.path returned nil for \(filename).\(fileExtension)")
            print("Error: \(filename).\(fileExtension) not found in bundle.")
            return
        }

        // 進行額外檢查：確認檔案是否存在於給定的路徑
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: bundlePath) {
            print("DEBUG: FileManager reports file DOES NOT EXIST at path: \(bundlePath)")
            print("Error: \(filename).\(fileExtension) not found in bundle, despite Bundle.main.path returning a path.")
            return
        }

        print("DEBUG: File found at path: \(bundlePath)") // 如果能執行到這行，表示路徑獲取成功

        do {
            let csvString = try String(contentsOfFile: bundlePath, encoding: .utf8)
            print("CSV Content Loaded Successfully from file.")

            // 調用 CSVImporter 來解析 CSV 字串
            let importedAssets = CSVImporter.importAssets(from: csvString)

            // 在主線程上更新 assets 屬性
            DispatchQueue.main.async { [weak self] in // 確保這裡有 [weak self] in
                guard let self = self else { return }
                self.assets = importedAssets
                print("Successfully loaded \(self.assets.count) assets from CSV via CSVImporter.")
            }

        } catch {
            print("Error loading CSV file: \(error.localizedDescription)")
        }
    }
    // 您也可以添加一個函數來直接從內建的 generateSampleCSV 數據載入
    func loadGeneratedSampleAssets() {
        let csvString = CSVImporter.generateSampleCSV()
        let importedAssets = CSVImporter.importAssets(from: csvString)

        DispatchQueue.main.async {
            self.assets = importedAssets
            print("Successfully loaded \(self.assets.count) assets from generated CSV.")
        }
    }


}

// MARK: - Convenience Methods
extension AssetManager {
    func assetsSortedByValue(ascending: Bool = false) -> [Asset] {
        assets.sorted { ascending ? $0.value < $1.value : $0.value > $1.value }
    }

    func assetsSortedByDate(ascending: Bool = false) -> [Asset] {
        assets.sorted { ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
    }

    func assetsGroupedByCategory() -> [AssetCategory: [Asset]] {
        Dictionary(grouping: assets) { $0.category }
    }

    func categoryTotals() -> [AssetCategory: Double] {
        var totals: [AssetCategory: Double] = [:]
        for category in AssetCategory.allCases {
            totals[category] = totalValue(for: category)
        }
        return totals
    }

    // MARK: - Reset Data
    func resetAllData() {
        // 清除所有資料
        storageManager.clearAllData()
        // 重置內存中的資料
        assets = []
        assetHistory = []
        // 發送通知資料已更新
        objectWillChange.send()
    }
}


