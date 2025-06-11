import SwiftUI
//import AssetManager
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
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
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
    @ObservedObject var stockService: StockService
    @State private var currentPrice: Double?
    @State private var isLoading = false
    @State private var error: String?
    @State private var fetchTask: Task<Void, Never>?

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
        // Use stockService.currentStockPrices directly
        let symbol = isUSStock ? asset.name : (asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW")
        guard let price = stockService.currentStockPrices[symbol] else { return asset.valueInTWD } // Fallback to asset.valueInTWD

        if isUSStock {
            return Double(shares) * price * stockService.usdExchangeRate
        } else {
            return Double(shares) * price
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }

    private func cancelFetchTask() {
        fetchTask?.cancel()
        fetchTask = nil
    }

    func fetchStockPrice() {
        cancelFetchTask()

        isLoading = true
        error = nil

        fetchTask = Task {
            do {
                if Task.isCancelled { return }

                let stockSymbol = asset.additionalInfo["symbol"]?.string ?? asset.name
                currentPrice = try await isUSStock ?
                    stockService.fetchUSStockPrice(symbol: stockSymbol) :
                    stockService.fetchTWStockPrice(symbol: stockSymbol)

                // Removed: stockValues[asset.id.uuidString] = value
            } catch is CancellationError {
                // Ignore cancellation errors
                return
            } catch {
                if !Task.isCancelled {
                    self.error = "無法獲取價格"
                    print("Error fetching stock price: \(error)")
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
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
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                } else { // Removed currentPrice check here as totalValue uses stockService directly
                    if isUSStock {
                        Text("$\(String(format: "%.2f", stockService.currentStockPrices[isUSStock ? asset.name : (asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW")] ?? 0))")
                            .font(.headline)
                        Text(formatCurrency(totalValue))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    } else {
                        Text("NT$\(String(format: "%.2f", stockService.currentStockPrices[isUSStock ? asset.name : (asset.name.hasSuffix(".TW") ? asset.name : "\(asset.name).TW")] ?? 0))")
                            .font(.headline)
                        Text(formatCurrency(totalValue))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            // StockRowView only needs to trigger a fetch for its specific stock if not already available in StockService
            // Or, ideally, AssetManager already handles the initial fetch for all assets.
            // For now, let\'s keep fetchStockPrice() to ensure price is fetched for this row.
            fetchStockPrice() // Ensure fetchStockPrice is called here.
        }
        .onDisappear {
            cancelFetchTask()
        }
    }
}

//struct StockEditView: View {
//    @Environment(\.dismiss) private var dismiss
//    @EnvironmentObject var assetManager: AssetManager
//    @StateObject private var stockService = StockService.shared
//
//    let mode: AssetEditMode
//    let stockType: StockView.StockType
//    let initialAsset: Asset?
//
//    @State private var symbol: String = ""
//    @State private var shares: String = ""
//    @State private var isLoading = false
//    @State private var error: String?
//    @State private var currentPrice: Double?
//    @State private var showingDeleteAlert = false
//    @State private var fetchTask: Task<Void, Never>?
//
//    private func cancelFetchTask() {
//        fetchTask?.cancel()
//        fetchTask = nil
//    }
//
//    private func formatCurrency(_ value: Double, includeDecimals: Bool = false) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = Locale(identifier: "zh_TW")
//        formatter.minimumFractionDigits = includeDecimals ? 2 : 0
//        formatter.maximumFractionDigits = includeDecimals ? 2 : 0
//        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
//    }
//
//    private func formatPrice(_ price: Double) -> String {
//        if stockType == .us {
//            return "$\(String(format: "%.2f", price))"
//        } else {
//            return "NT$\(String(format: "%.2f", price))"
//        }
//    }
//
//    private func fetchStockPrice() {
//        guard !symbol.isEmpty else { return }
//
//        // Cancel any existing fetch task
//        cancelFetchTask()
//
//        isLoading = true
//        error = nil
//        currentPrice = nil
//
//        fetchTask = Task {
//            do {
//                if Task.isCancelled { return }
//
//                if stockType == .us {
//                    currentPrice = try await stockService.fetchUSStockPrice(symbol: symbol)
//                } else {
//                    let symbolWithTW = symbol.hasSuffix(".TW") ? symbol : "\(symbol).TW"
//                    currentPrice = try await stockService.fetchTWStockPrice(symbol: symbolWithTW)
//                }
//            } catch is CancellationError {
//                // Ignore cancellation errors
//                return
//            } catch {
//                if !Task.isCancelled {
//                    print("Error fetching stock price: \(error)")
//                    self.error = "無法獲取價格：\(error.localizedDescription)"
//                }
//            }
//
//            if !Task.isCancelled {
//                isLoading = false
//            }
//        }
//    }
//
//    var body: some View {
//        Form {
//            Section(header: Text("股票資訊")) {
//                TextField("股票代碼", text: $symbol)
//                TextField("股數", text: $shares)
//
//                if isLoading {
//                    HStack {
//                        Spacer()
//                        ProgressView()
//                        Spacer()
//                    }
//                } else if let price = currentPrice { // Keep this currentPrice local to StockEditView for display
//                    HStack {
//                        Text("現價")
//                        Spacer()
//                        Text(formatPrice(price))
//                            .foregroundColor(.blue)
//                    }
//
//                    if stockType == .us {
//                        HStack {
//                            Text("台幣價格")
//                            Spacer()
//                            Text(formatCurrency(price * stockService.usdExchangeRate, includeDecimals: true))
//                                .foregroundColor(.blue)
//                        }
//                    }
//
//                    if let sharesNum = Int(shares) {
//                        let value = price * Double(sharesNum) * (stockType == .us ? stockService.usdExchangeRate : 1)
//                        HStack {
//                            Text("市值")
//                            Spacer()
//                            Text(formatCurrency(value))
//                                .foregroundColor(.blue)
//                        }
//                    }
//                }
//
//                if let error = error {
//                    Text(error)
//                        .font(.caption)
//                        .foregroundColor(.red)
//                }
//            }
//
//            if mode == .edit {
//                Section {
//                    Button(role: .destructive) {
//                        showingDeleteAlert = true
//                    } label: {
//                        HStack {
//                            Spacer()
//                            Text("刪除股票")
//                            Spacer()
//                        }
//                    }
//                }
//            }
//        }
//        .navigationTitle(mode == .add ? "新增股票" : "編輯股票")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button("取消") {
//                    dismiss()
//                }
//            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("儲存") {
//                    saveStock()
//                }
//                .disabled(isLoading || currentPrice == nil || shares.isEmpty)
//            }
//        }
//        .alert("確認刪除", isPresented: $showingDeleteAlert) {
//            Button("取消", role: .cancel) { }
//            Button("刪除", role: .destructive) {
//                deleteStock()
//            }
//        } message: {
//            Text("確定要刪除這個股票嗎？此操作無法撤銷。")
//        }
//        .onChange(of: symbol) { oldValue, newValue in
//            if oldValue != newValue {
//                fetchStockPrice()
//            }
//        }
//        .onAppear {
//            if let asset = initialAsset {
//                symbol = asset.additionalInfo["symbol"]?.string ?? asset.name
//                shares = asset.additionalInfo["shares"]?.string ?? ""
//                fetchStockPrice() // Fetch price for initial asset
//            }
//        }
//        .onDisappear {
//            cancelFetchTask()
//        }
//    }
//
//    private func saveStock() {
//        guard let price = currentPrice,
//              let sharesNum = Int(shares) else { return }
//
//        let value = price * Double(sharesNum) * (stockType == .us ? stockService.usdExchangeRate : 1)
//        let additionalInfo: [String: AdditionalInfoValue] = [
//            "symbol": .string(symbol),
//            "shares": .string(shares),
//            "isUSStock": .string(stockType == .us ? "true" : "false")
//        ]
//
//        let asset = Asset(
//            id: initialAsset?.id ?? UUID(),
//            category: .stock,
//            name: symbol,
//            value: value,
//            additionalInfo: additionalInfo,
//            createdAt: initialAsset?.createdAt ?? Date(),
//            updatedAt: Date()
//        )
//
//        if mode == .add {
//            assetManager.addAsset(asset)
//        } else {
//            assetManager.updateAsset(asset)
//        }
//
//        dismiss()
//    }
//
//    private func deleteStock() {
//        if let asset = initialAsset {
//            assetManager.deleteAsset(asset)
//        }
//        dismiss()
//    }
//}

// #Preview {
//     StockView()
//         .environmentObject(AssetManager.shared)
// }
