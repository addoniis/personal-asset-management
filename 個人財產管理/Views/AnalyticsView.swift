import SwiftUI
import Charts

struct AssetData: Identifiable {
    let id = UUID()
    let type: String
    let amount: Double
    let color: Color
}

struct AnalyticsView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var isLoading = false

    private var assetData: [AssetData] {
        [
            AssetData(type: "現金", amount: assetManager.totalCash, color: .blue),
            AssetData(type: "股票", amount: assetManager.totalStocks, color: .green),
            AssetData(type: "不動產", amount: assetManager.totalProperties, color: .orange),
            AssetData(type: "保險", amount: assetManager.totalInsurance, color: .purple)
        ]
    }

    var body: some View {
        NavigationView {
            List {
                if assetManager.totalAssets > 0 {
                    Section("資產配置") {
                        Chart(assetData.filter { $0.amount > 0 }) { data in
                            SectorMark(
                                angle: .value("金額", data.amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(data.color)
                            .annotation(position: .overlay) {
                                Text("\(data.type)\n\(formatPercentage(data.amount / assetManager.totalAssets))")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(height: 300)
                        .padding()
                    }
                }

                Section("資產總覽") {
                    HStack {
                        Text("總資產")
                        Spacer()
                        Text("NT$ \(formatNumber(assetManager.totalAssets))")
                            .foregroundColor(.primary)
                    }

                    ForEach(assetData) { data in
                        if data.amount > 0 {
                            AssetSummaryRow(
                                title: data.type,
                                amount: data.amount,
                                color: data.color
                            )
                        }
                    }
                }
            }
            .navigationTitle("資產分析")
            .refreshable {
                isLoading = true
                await assetManager.loadAssets()
                isLoading = false
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

struct AssetSummaryRow: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
            Spacer()
            Text("NT$ \(formatNumber(amount))")
                .foregroundColor(.secondary)
        }
    }

    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(AssetManager.shared)
}
