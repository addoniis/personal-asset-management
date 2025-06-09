import SwiftUI

struct CashView: View {
    @EnvironmentObject var assetManager: AssetManager

    private var cashAssets: [Asset] {
        assetManager.assets(for: .cash)
    }

    private var totalCash: Double {
        cashAssets.reduce(0) { $0 + floor($1.value) }
    }

    var body: some View {
        NavigationStack {
            List {
                TotalAssetsHeaderView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section(header: Text("現金資產總覽")) {
                    HStack {
                        Text("現金總額")
                        Spacer()
                        Text(formatCurrencyAsInteger(totalCash))
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("現金明細")) {
                    if cashAssets.isEmpty {
                        Text("尚無現金資產")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(cashAssets) { asset in
                            CashRowView(asset: asset)
                        }
                    }
                }
            }
            .navigationTitle("現金")
        }
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .down
        return formatter.string(from: NSNumber(value: floor(value))) ?? "NT$0"
    }
}

#Preview {
    CashView()
        .environmentObject(AssetManager.shared)
}
