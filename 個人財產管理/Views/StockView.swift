import SwiftUI

struct StockView: View {
    @StateObject private var assetManager = AssetManager.shared
    @State private var showingAddStock = false
    @State private var selectedMarket: StockMarket = .taiwan

    enum StockMarket: String, CaseIterable {
        case taiwan = "台股"
        case us = "美股"
    }

    private var stockAssets: [Asset] {
        assetManager.assets.filter { $0.category == .stock }
    }

    private var totalStockValue: Double {
        stockAssets.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 總股票資產卡片
                    AssetCardView(
                        title: "總股票資產",
                        amount: totalStockValue,
                        trend: assetManager.getGrowthRate(for: .stock),
                        color: AssetCategory.stock.color
                    )
                    .padding(.horizontal)

                    // 市場選擇器
                    Picker("股票市場", selection: $selectedMarket) {
                        ForEach(StockMarket.allCases, id: \.self) { market in
                            Text(market.rawValue).tag(market)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 股票資產趨勢
                    AssetTrendChartView(
                        data: assetManager.getAssetHistory(for: .stock, months: 12).map { history in
                            AssetTrendChartView.DataPoint(
                                date: history.date,
                                value: history.totalValue
                            )
                        },
                        title: "股票資產趨勢"
                    )
                    .padding(.horizontal)

                    // 股票列表
                    LazyVStack(spacing: 16) {
                        ForEach(stockAssets) { stock in
                            StockCard(stock: stock)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("股票")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddStock = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStock) {
                AddStockView(market: selectedMarket)
            }
        }
    }
}

// 股票卡片視圖
struct StockCard: View {
    let stock: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stock.name)
                    .font(.headline)

                if !stock.notes.isEmpty {
                    Text(stock.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("$\(String(format: "%.2f", stock.amount))")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // 這裡可以添加更多股票相關信息，如漲跌幅、持股數量等
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// 新增股票視圖
struct AddStockView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetManager = AssetManager.shared
    @State private var stockName = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    let market: StockMarket

    var body: some View {
        NavigationView {
            AssetInputForm(
                assetName: $stockName,
                amount: $amount,
                category: .constant(.stock),
                date: $date,
                notes: $notes
            ) {
                if let amountValue = Double(amount) {
                    let stock = Asset(
                        id: UUID(),
                        name: stockName,
                        amount: amountValue,
                        category: .stock,
                        date: date,
                        notes: "\(market.rawValue): \(notes)"
                    )
                    assetManager.addAsset(stock)
                    dismiss()
                }
            }
            .navigationTitle("新增\(market.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StockView()
}
