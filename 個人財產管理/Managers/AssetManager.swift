import Foundation
import Combine

class AssetManager: ObservableObject {
    static let shared = AssetManager()
    private let storageManager = StorageManager.shared

    @Published private(set) var assets: [Asset] = []
    @Published private(set) var assetHistory: [AssetHistory] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private var cancellables = Set<AnyCancellable>()

    struct AssetHistory: Identifiable {
        let id = UUID()
        let date: Date
        let totalValue: Double
        let growthRate: Double
    }

    var totalAssets: Double {
        assets.reduce(0) { $0 + $1.amount }
    }

    var assetsByCategory: [AssetCategory: Double] {
        Dictionary(grouping: assets, by: { $0.category })
            .mapValues { assets in
                assets.reduce(0) { $0 + $1.amount }
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
        loadAssets()
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
    private func loadAssets() {
        isLoading = true
        error = nil

        do {
            assets = try storageManager.loadAssets()
        } catch {
            self.error = error.localizedDescription
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
        storageManager.saveAssetHistory(assetHistory)
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

    func restoreFromBackup(at url: URL) throws {
        try storageManager.restoreFromBackup(at: url)
        loadAssets()
    }

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

    func getGrowthRate(for category: AssetCategory) -> Double {
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        let currentValue = assetsByCategory[category] ?? 0

        let lastMonthAssets = assetHistory.first { history in
            Calendar.current.isDate(history.date, equalTo: lastMonth, toGranularity: .month)
        }
        guard let lastMonthValue = lastMonthAssets?.totalValue, lastMonthValue > 0 else { return 0 }

        return ((currentValue - lastMonthValue) / lastMonthValue) * 100
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
}
