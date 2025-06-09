import Foundation
import Combine
import SwiftUI

class AssetManager: ObservableObject {
    static let shared = AssetManager()
    private let storageManager = StorageManager.shared

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
        assets.reduce(0) { $0 + $1.value }
    }

    var totalCash: Double {
        assets.filter { $0.category == .cash }.reduce(0) { $0 + $1.value }
    }

    var totalStocks: Double {
        assets.filter { $0.category == .stock }.reduce(0) { $0 + $1.value }
    }

    var totalProperties: Double {
        assets.filter { $0.category == .property }.reduce(0) { $0 + $1.value }
    }

    var totalInsurance: Double {
        assets.filter { $0.category == .insurance }.reduce(0) { $0 + $1.value }
    }

    var assetsByCategory: [AssetCategory: Double] {
        Dictionary(grouping: assets, by: { $0.category })
            .mapValues { assets in
                assets.reduce(0) { $0 + $1.value }
            }
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
        }
        loadHistory()
    }

    // MARK: - CRUD Operations
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        saveAssets()
        updateHistory()
    }

    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            saveAssets()
            updateHistory()
        }
    }

    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        saveAssets()
        updateHistory()
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
        assets(for: category).reduce(0) { $0 + $1.value }
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
            let noteStr = asset.note.replacingOccurrences(of: ",", with: "，") // 避免逗號影響CSV格式

            switch asset.category {
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
            default:
                categoryStr = asset.category.displayName
                quantityStr = String(format: "%.0f", asset.value)
                nameStr = asset.name
            }

            csv += "\(categoryStr),\(nameStr),\(quantityStr),\(dateFormatter.string(from: asset.createdAt)),\(noteStr)\n"
        }

        return csv
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
