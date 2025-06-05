import SwiftUI

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
            .reduce(0) { $0 + $1.value }
    }

    private var usStockValue: Double {
        stockAssets
            .filter { $0.additionalInfo["isUSStock"]?.string == "true" }
            .reduce(0) { $0 + $1.value }
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    var body: some View {
        NavigationView {
            VStack {
                // 總覽區域
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
                            Text(formatCurrencyAsInteger(usStockValue))
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
                        Text(formatCurrencyAsInteger(twStockValue + usStockValue))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                // 股票類型選擇器
                Picker("股票類型", selection: $stockType) {
                    ForEach(StockType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if stockType == .us {
                    // 顯示美元匯率
                    HStack {
                        Text("目前美元匯率：")
                        Text(String(format: "%.2f", stockService.usdExchangeRate))
                            .foregroundColor(.blue)
                        Text("TWD/USD")
                    }
                    .padding(.horizontal)
                }

                List {
                    Section(header: Text("當前類別總覽")) {
                        HStack {
                            Text("總市值")
                            Spacer()
                            Text(formatCurrencyAsInteger(calculateTotalValue()))
                                .foregroundColor(.blue)
                        }
                    }

                    Section(header: Text("股票明細")) {
                        ForEach(filterStocks()) { asset in
                            StockRowView(asset: asset, stockService: stockService)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAsset = asset
                                }
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
                NavigationView {
                    StockEditView(
                        mode: .add,
                        stockType: stockType,
                        initialAsset: nil
                    )
                }
            }
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    StockEditView(
                        mode: .edit,
                        stockType: getStockType(from: asset),
                        initialAsset: asset
                    )
                }
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
        filterStocks().reduce(0) { total, asset in
            let isUSStock = asset.additionalInfo["isUSStock"]?.string == "true"
            if isUSStock {
                return total + (asset.value * stockService.usdExchangeRate)
            } else {
                return total + asset.value
            }
        }
    }

    private func getStockType(from asset: Asset) -> StockType {
        asset.additionalInfo["isUSStock"]?.string == "true" ? .us : .taiwan
    }
}

struct StockRowView: View {
    let asset: Asset
    let stockService: StockService
    @State private var currentPrice: Double?
    @State private var isLoading = false
    @State private var error: String?

    private var isUSStock: Bool {
        asset.additionalInfo["isUSStock"]?.string == "true"
    }

    private var shares: Int {
        if let sharesString = asset.additionalInfo["shares"]?.string,
           let shares = Int(sharesString) {
            return shares
        }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                } else if let price = currentPrice {
                    VStack(alignment: .trailing) {
                        Text(formatCurrency(price))
                            .foregroundColor(.blue)
                        if isUSStock {
                            Text(formatCurrency(price * stockService.usdExchangeRate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            HStack {
                Text("股數：\(shares)")
                Spacer()
                if let price = currentPrice {
                    let value = Double(shares) * price * (isUSStock ? stockService.usdExchangeRate : 1)
                    Text("市值：\(formatCurrency(value))")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            fetchStockPrice()
        }
    }

    private func fetchStockPrice() {
        guard let symbol = asset.additionalInfo["symbol"]?.string else { return }
        isLoading = true
        error = nil

        Task {
            do {
                if isUSStock {
                    currentPrice = try await stockService.fetchUSStockPrice(symbol: symbol)
                } else {
                    currentPrice = try await stockService.fetchTWStockPrice(symbol: symbol)
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct StockEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager
    @StateObject private var stockService = StockService.shared

    let mode: AssetEditMode
    let stockType: StockView.StockType
    let initialAsset: Asset?

    @State private var symbol: String = ""
    @State private var shares: String = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var currentPrice: Double?
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text("股票資訊")) {
                TextField("股票代碼", text: $symbol)
                    .textInputAutocapitalization(.never)
                TextField("股數", text: $shares)
                    .keyboardType(.numberPad)

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let price = currentPrice {
                    HStack {
                        Text("現價")
                        Spacer()
                        Text(formatCurrency(price))
                            .foregroundColor(.blue)
                    }

                    if stockType == .us {
                        HStack {
                            Text("台幣價格")
                            Spacer()
                            Text(formatCurrency(price * stockService.usdExchangeRate))
                                .foregroundColor(.blue)
                        }
                    }

                    if let sharesNum = Int(shares) {
                        let value = price * Double(sharesNum) * (stockType == .us ? stockService.usdExchangeRate : 1)
                        HStack {
                            Text("市值")
                            Spacer()
                            Text(formatCurrency(value))
                                .foregroundColor(.blue)
                        }
                    }
                }

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if mode == .edit {
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("刪除股票")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(mode == .add ? "新增股票" : "編輯股票")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    saveStock()
                }
                .disabled(isLoading || currentPrice == nil || shares.isEmpty)
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteStock()
            }
        } message: {
            Text("確定要刪除這個股票嗎？此操作無法撤銷。")
        }
        .onChange(of: symbol) { _ in
            fetchStockPrice()
        }
        .onAppear {
            if let asset = initialAsset {
                symbol = asset.additionalInfo["symbol"]?.string ?? ""
                shares = asset.additionalInfo["shares"]?.string ?? ""
                fetchStockPrice()
            }
        }
    }

    private func fetchStockPrice() {
        guard !symbol.isEmpty else { return }
        isLoading = true
        error = nil
        currentPrice = nil

        Task {
            do {
                if stockType == .us {
                    currentPrice = try await stockService.fetchUSStockPrice(symbol: symbol)
                } else {
                    currentPrice = try await stockService.fetchTWStockPrice(symbol: symbol)
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveStock() {
        guard let price = currentPrice,
              let sharesNum = Int(shares) else { return }

        let value = price * Double(sharesNum) * (stockType == .us ? stockService.usdExchangeRate : 1)
        let additionalInfo: [String: AdditionalInfoValue] = [
            "symbol": .string(symbol),
            "shares": .string(shares),
            "isUSStock": .string(stockType == .us ? "true" : "false")
        ]

        let asset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: .stock,
            name: "\(symbol) (\(shares)股)",
            value: value,
            additionalInfo: additionalInfo,
            createdAt: initialAsset?.createdAt ?? Date(),
            updatedAt: Date()
        )

        if mode == .add {
            assetManager.addAsset(asset)
        } else {
            assetManager.updateAsset(asset)
        }

        dismiss()
    }

    private func deleteStock() {
        if let asset = initialAsset {
            assetManager.deleteAsset(asset)
        }
        dismiss()
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    StockView()
        .environmentObject(AssetManager.shared)
}
