import SwiftUI

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
    @State private var fetchTask: Task<Void, Never>?

    private func cancelFetchTask() {
        fetchTask?.cancel()
        fetchTask = nil
    }

    private func formatCurrency(_ value: Double, includeDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.minimumFractionDigits = includeDecimals ? 2 : 0
        formatter.maximumFractionDigits = includeDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }

    private func formatPrice(_ price: Double) -> String {
        if stockType == .us {
            return "$\(String(format: "%.2f", price))"
        } else {
            return "NT$\(String(format: "%.2f", price))"
        }
    }

    private func fetchStockPrice() {
        guard !symbol.isEmpty else { return }

        // Cancel any existing fetch task
        cancelFetchTask()

        isLoading = true
        error = nil
        currentPrice = nil

        fetchTask = Task {
            do {
                if Task.isCancelled { return }

                if stockType == .us {
                    currentPrice = try await stockService.fetchUSStockPrice(symbol: symbol)
                } else {
                    let symbolWithTW = symbol.hasSuffix(".TW") ? symbol : "\(symbol).TW"
                    currentPrice = try await stockService.fetchTWStockPrice(symbol: symbolWithTW)
                }
            } catch is CancellationError {
                // Ignore cancellation errors
                return
            } catch {
                if !Task.isCancelled {
                    print("Error fetching stock price: \(error)")
                    self.error = "無法獲取價格：\(error.localizedDescription)"
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    var body: some View {
        Form {
            Section(header: Text("股票資訊")) {
                TextField("股票代碼", text: $symbol)
                TextField("股數", text: $shares)

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let price = currentPrice { // Keep this currentPrice local to StockEditView for display
                    HStack {
                        Text("現價")
                        Spacer()
                        Text(formatPrice(price))
                            .foregroundColor(.blue)
                    }

                    if stockType == .us {
                        HStack {
                            Text("台幣價格")
                            Spacer()
                            Text(formatCurrency(price * stockService.usdExchangeRate, includeDecimals: true))
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
        .onChange(of: symbol) { oldValue, newValue in
            if oldValue != newValue {
                fetchStockPrice()
            }
        }
        .onAppear {
            if let asset = initialAsset {
                symbol = asset.additionalInfo["symbol"]?.string ?? asset.name
                shares = asset.additionalInfo["shares"]?.string ?? ""
                fetchStockPrice() // Fetch price for initial asset
            }
        }
        .onDisappear {
            cancelFetchTask()
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
            name: symbol,
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
}
