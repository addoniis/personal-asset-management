import SwiftUI

struct CashView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil

    private var cashAssets: [Asset] {
        assetManager.assets(for: .cash)
    }

    private var totalValue: Double {
        cashAssets.reduce(0) { $0 + $1.valueInTWD }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TotalAssetsHeaderView()
                        .listRowInsets(EdgeInsets())
                }

                Section(header: Text("現金資產總覽")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("現金總覽")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        VStack {
                            Text("總金額")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(formatCurrencyAsInteger(totalValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }

                ForEach(Dictionary(grouping: cashAssets) { $0.additionalInfo["currency"]?.string ?? "TWD" }.sorted(by: { $0.key < $1.key }), id: \.key) { currency, assets in
                    Section(header: Text(currencyHeader(for: currency))) {
                        ForEach(assets) { asset in
                            CashRowView(asset: asset)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAsset = asset
                                }
                        }

                        if let currencyType = Currency(rawValue: currency) {
                            HStack {
                                Text("小計")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrencyAsInteger(assets.reduce(0) { $0 + $1.value } * currencyType.exchangeRate))
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("現金資產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    CashEditView(mode: .add, initialAsset: nil)
                }
            }
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    CashEditView(mode: .edit, initialAsset: asset)
                }
            }
        }
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }

    private func currencyHeader(for currency: String) -> String {
        guard let currencyType = Currency(rawValue: currency) else {
            return currency
        }
        if currencyType == .twd {
            return currencyType.displayName
        } else {
            return "\(currencyType.displayName) (匯率\(String(format: "%.2f", currencyType.exchangeRate)))"
        }
    }
}

#Preview {
    CashView()
        .environmentObject(AssetManager.shared)
}
