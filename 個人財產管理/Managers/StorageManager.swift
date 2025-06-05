import Foundation
import SwiftUI

class StorageManager {
    static let shared = StorageManager()

    private let assetsKey = "assets"
    private let historyKey = "assetHistory"
    private let userDefaults = UserDefaults.standard

    private init() {}

    func saveAssets(_ assets: [Asset]) throws {
        let encoded = try JSONEncoder().encode(assets)
        userDefaults.set(encoded, forKey: assetsKey)
    }

    func loadAssets() throws -> [Asset] {
        guard let data = userDefaults.data(forKey: assetsKey) else {
            return []
        }
        return try JSONDecoder().decode([Asset].self, from: data)
    }

    func saveAssetHistory(_ history: [AssetManager.AssetHistory]) throws {
        let encoded = try JSONEncoder().encode(history)
        userDefaults.set(encoded, forKey: historyKey)
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

    func createBackup() throws -> URL {
        let exportData = ExportData(
            assets: try loadAssets(),
            history: loadAssetHistory()
        )
        let encoded = try JSONEncoder().encode(exportData)

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupURL = documentsDirectory.appendingPathComponent("asset_backup_\(Date()).json")
        try encoded.write(to: backupURL)
        return backupURL
    }

    func restoreFromBackup(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        try saveAssets(importData.assets)
        try saveAssetHistory(importData.history)
    }
}

// MARK: - Supporting Types
private struct ExportData: Codable {
    let assets: [Asset]
    let history: [AssetManager.AssetHistory]
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
