import Foundation

class StorageManager {
    static let shared = StorageManager()

    private let assetsKey = "assets"
    private let historyKey = "assetHistory"
    private let userDefaults = UserDefaults.standard

    private init() {}

    func saveAssets(_ assets: [Asset]) {
        if let encoded = try? JSONEncoder().encode(assets) {
            userDefaults.set(encoded, forKey: assetsKey)
        }
    }

    func loadAssets() -> [Asset] {
        guard let data = userDefaults.data(forKey: assetsKey),
              let assets = try? JSONDecoder().decode([Asset].self, from: data) else {
            return []
        }
        return assets
    }

    func saveAssetHistory(_ history: [AssetManager.AssetHistory]) {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }

    func loadAssetHistory() -> [AssetManager.AssetHistory] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([AssetManager.AssetHistory].self, from: data) else {
            return []
        }
        return history
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: assetsKey)
        userDefaults.removeObject(forKey: historyKey)
    }

    func exportData() -> Data? {
        let assets = loadAssets()
        let history = loadAssetHistory()

        let exportData = ExportData(assets: assets, history: history)
        return try? JSONEncoder().encode(exportData)
    }

    func importData(_ data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(ExportData.self, from: data) else {
            return false
        }

        saveAssets(importData.assets)
        saveAssetHistory(importData.history)
        return true
    }

    private struct ExportData: Codable {
        let assets: [Asset]
        let history: [AssetManager.AssetHistory]
    }
}

// MARK: - Errors
enum StorageError: Error {
    case backupNotFound
    case invalidData
    case saveFailed
    case loadFailed

    var localizedDescription: String {
        switch self {
        case .backupNotFound:
            return "找不到備份文件"
        case .invalidData:
            return "數據格式無效"
        case .saveFailed:
            return "保存失敗"
        case .loadFailed:
            return "讀取失敗"
        }
    }
}
