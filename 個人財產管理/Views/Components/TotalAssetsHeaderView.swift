import SwiftUI

struct TotalAssetsHeaderView: View {
    @EnvironmentObject var assetManager: AssetManager
    @StateObject private var stockService = StockService.shared

    private var totalAssets: Double {
        let cashAssets = assetManager.assets(for: .cash).reduce(0) { $0 + $1.value }
        let propertyAssets = assetManager.assets(for: .property).reduce(0) { $0 + $1.value }
        let insuranceAssets = assetManager.assets(for: .insurance).reduce(0) { $0 + $1.value }

        // 股票資產需要特別處理，因為有美股轉換
        let stockAssets = assetManager.assets(for: .stock)
        let twStocks = stockAssets.filter { $0.additionalInfo["isUSStock"]?.string != "true" }
        let usStocks = stockAssets.filter { $0.additionalInfo["isUSStock"]?.string == "true" }

        let twStockValue = twStocks.reduce(0) { $0 + $1.value }
        let usStockValue = usStocks.reduce(0) { $0 + $1.value } * stockService.usdExchangeRate

        return cashAssets + twStockValue + usStockValue + propertyAssets + insuranceAssets
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("總資產")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(formatCurrencyAsInteger(totalAssets))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .down
        return formatter.string(from: NSNumber(value: floor(value)))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }
}

#Preview {
    TotalAssetsHeaderView()
        .environmentObject(AssetManager.shared)
}
