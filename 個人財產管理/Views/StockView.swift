import SwiftUI
//import AssetManager // 確保這些模組有被正確導入
//import StockService
//import Models
//import TotalAssetsHeaderView
//import AssetEditMode

struct StockView: View {
    @EnvironmentObject var assetManager: AssetManager
    @StateObject private var stockService = StockService.shared
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil
    @State private var stockType: StockType = .taiwan

    enum StockType: String, CaseIterable {
        case taiwan = "台股"
        case us = "美股"
    }

    private var stockAssets: [Asset] {
        assetManager.assets(for: .stock)
    }

    private var twStockValue: Double {
        stockAssets
            .filter { $0.additionalInfo["isUSStock"]?.string != "true" }
            .reduce(0) { total, asset in
                guard let shares = asset.additionalInfo["shares"]?.double else { return total + asset.valueInTWD }
                let symbol = asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW"
                let price = stockService.currentStockPrices[symbol]
                // If live price is not available, use the stored total value for the asset
                if let currentPrice = price { return total + (currentPrice * shares) }
                else { return total + asset.valueInTWD }
            }
    }

    private var usStockValue: Double {
        stockAssets
            .filter { $0.additionalInfo["isUSStock"]?.string == "true" }
            .reduce(0) { total, asset in
                guard let shares = asset.additionalInfo["shares"]?.double else { return total + asset.valueInTWD }
                let symbol = asset.name
                let price = stockService.currentStockPrices[symbol]
                // If live price is not available, use the stored total value for the asset
                if let currentPrice = price { return total + (currentPrice * shares * stockService.usdExchangeRate) }
                else { return total + asset.valueInTWD }
            }
    }

    private var totalStockValue: Double {
        twStockValue + usStockValue // usStockValue is already in TWD here
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TotalAssetsHeaderView()
                        .listRowInsets(EdgeInsets())
                }

                Section(header: Text("股票資產總覽")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("股票資產總覽")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 上排：台股和美股
                        HStack(spacing: 20) {
                            VStack {
                                Text("台股總值")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatCurrencyAsInteger(twStockValue))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text("美股總值")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatCurrencyAsInteger(usStockValue)) // Already in TWD
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // 下排：股票總值
                        VStack {
                            Text("股票總值")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(formatCurrencyAsInteger(totalStockValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)

                        // 顯示美元匯率
                        HStack {
                            Text("目前美元匯率：")
                            Text(String(format: "%.2f", stockService.usdExchangeRate))
                                .foregroundColor(.blue)
                            Text("TWD/USD")
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                    .padding(.vertical)
                }

                Section {
                    Picker("股票類型", selection: $stockType) {
                        ForEach(StockType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .padding()
                }

                Section {
                    ForEach(filterStocks()) { asset in
                        StockRowView(asset: asset, stockService: stockService) // Pass only stockService
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAsset = asset
                            }
                    }
                }
            }
            .navigationTitle("股票")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack { // 使用 HStack 包裹兩個按鈕
                        Button(action: {
                            // 手動觸發價格更新
                            Task { await assetManager.fetchRealtimeStockPrices() }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath") // 刷新圖標
                        }
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    StockEditView(
                        mode: AssetEditMode.add,
                        stockType: stockType,
                        initialAsset: nil as Asset?
                    )
                }
            }
            .sheet(item: $selectedAsset) { (asset: Asset) in // Explicitly type asset
                NavigationStack {
                    StockEditView(
                        mode: AssetEditMode.edit,
                        stockType: getStockType(from: asset),
                        initialAsset: asset
                    )
                }
            }
            .onAppear {
                // 應用第一次載入時自動刷新一次價格
                Task { await assetManager.fetchRealtimeStockPrices() }
            }
        }
    }

    private func filterStocks() -> [Asset] {
        stockAssets.filter { asset in
            let isUSStock = asset.additionalInfo["isUSStock"]?.string == "true"
            return stockType == .us ? isUSStock : !isUSStock
        }
    }

    private func calculateTotalValue() -> Double {
        // This method seems redundant after implementing twStockValue and usStockValue
        // It is currently not used. If it is used elsewhere, its logic needs review.
        let currentTypeStocks = filterStocks()
        return currentTypeStocks.reduce(0) { total, asset in
            let isUSStock = asset.additionalInfo["isUSStock"]?.string == "true"
            if isUSStock {
                return total + asset.value // This might be original stored value, not live
            } else {
                return total + asset.value // This might be original stored value, not live
            }
        }
    }

    private func getStockType(from asset: Asset) -> StockType {
        asset.additionalInfo["isUSStock"]?.string == "true" ? .us : .taiwan
    }
}

struct StockRowView: View {
    let asset: Asset
    @ObservedObject var stockService: StockService // 保持為 @ObservedObject，確保響應 stockService 的更新
    // 移除 @State private var currentPrice: Double? 和相關的 isLoading, error, fetchTask
    // 因為現在 StockRowView 應直接從 stockService 中獲取價格

    private var isUSStock: Bool {
        asset.additionalInfo["isUSStock"]?.string == "true"
    }

    private var shares: Int {
        if let sharesStr = asset.additionalInfo["shares"]?.string,
           let shares = Int(sharesStr) {
            return shares
        }
        return 0
    }

    private var totalValue: Double {
        // 直接使用 stockService.currentStockPrices
        let symbol = isUSStock ? asset.name : (asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW")
        guard let price = stockService.currentStockPrices[symbol] else {
            // 如果即時價格尚未載入，則回退到資產的原始價值
            // 這確保在價格載入前不會顯示空白或 0
            return asset.valueInTWD
        }

        if isUSStock {
            return Double(shares) * price * stockService.usdExchangeRate
        } else {
            return Double(shares) * price
        }
    }

    private var currentDisplayPrice: Double {
        let symbol = isUSStock ? asset.name : (asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW")
        return stockService.currentStockPrices[symbol] ?? 0.0 // 如果沒有價格則顯示 0.0
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }
    

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.additionalInfo["symbol"]?.string ?? asset.name)
                    .font(.headline)
                Text("股數：\(shares)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // 這裡直接使用 currentDisplayPrice，它會自動從 stockService 中獲取最新價格
                if isUSStock {
                    Text("$\(String(format: "%.2f", currentDisplayPrice))")
                        .font(.headline)
                    Text(formatCurrency(totalValue))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                } else {
                    Text("NT$\(String(format: "%.2f", currentDisplayPrice))")
                        .font(.headline)
                    Text(formatCurrency(totalValue))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    StockView()
        .environmentObject(AssetManager.shared)
}

