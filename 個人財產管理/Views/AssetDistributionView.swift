import SwiftUI
import Foundation

struct AssetDistributionView: View {
    @EnvironmentObject var assetManager: AssetManager

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatAmount(_ amount: Double) -> String {
        let formattedNumber = numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "NT$ \(formattedNumber)"
    }

    var body: some View {
        // 直接用 PropertyView 的不動產淨值邏輯
        let propertyAssets = assetManager.assets(for: AssetCategory.property)
        let mortgageAssets = assetManager.assets(for: AssetCategory.mortgage)
        let propertyValue = propertyAssets.reduce(0) { $0 + $1.value }
        let mortgageValue = mortgageAssets.reduce(0) { $0 + $1.value }
        let realEstateNetValue = propertyValue - mortgageValue

        let rawPieData: [(String, Double, Color)] = [
            (AssetCategory.cash.rawValue, assetManager.assetsByCategory[.cash] ?? 0, AssetCategory.cash.color),
            (AssetCategory.stock.rawValue, assetManager.assetsByCategory[.stock] ?? 0, AssetCategory.stock.color), // Use real-time stock value from AssetManager
            (AssetCategory.fund.rawValue, assetManager.assetsByCategory[.fund] ?? 0, AssetCategory.fund.color),
            (AssetCategory.insurance.rawValue, assetManager.assetsByCategory[.insurance] ?? 0, AssetCategory.insurance.color),
            ("不動產", realEstateNetValue, AssetCategory.property.color),
            (AssetCategory.other.rawValue, assetManager.assetsByCategory[.other] ?? 0, AssetCategory.other.color)
        ]
        // MARK: - 圓餅圖數據處理與排序

        // 1. 過濾掉值為 0 的數據
        let filteredPieData = rawPieData.filter { $0.1 != 0 }
            
        // 2. 根據數值 (item.1) 進行降序排序，使圓餅圖按比例大小依序繪製
        let pieData = filteredPieData.sorted { $0.1 > $1.1 }

        // 3. 計算總和 (total) 應該基於排序和過濾後的 pieData
        let total = pieData.reduce(0) { $0 + $1.1 }
        
        
        ScrollView {
            VStack(spacing: 24) {
                // 總資產卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("總資產")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)

                    Text(formatAmount(assetManager.totalAssets))
                        .font(.system(size: 36, weight: .bold))
                        .padding(.horizontal)
                        .padding(.bottom)
                    Text(formatCurrencyInWan(assetManager.totalAssets))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)

                // 資產分布圓餅圖
                VStack(alignment: .leading, spacing: 0) {
                    Text("資產分布圖")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AssetPieChartView(
                        data: pieData,
                        total: total
                    )
                    .frame(height: 300)
                    .padding(.vertical)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)

                // 詳細資產列表
                VStack(alignment: .leading, spacing: 16) {
                    Text("詳細資產")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)

                    ForEach(pieData, id: \.0) { item in
                        HStack {
                            Circle()
                                .fill(item.2)
                                .frame(width: 12, height: 12)

                            Text(item.0)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(formatAmount(item.1))
                                    .font(.headline)

                                Text(String(format: "%.1f%%", (item.1 / total) * 100))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }  // foreach end
                    .padding(.bottom)
                }  //VStack end
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
            .padding()
        }//scrollview end
        .navigationTitle("資產分布")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    private func formatCurrencyInWan(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        let wan = floor(value / 10000)
        return "(\(formatter.string(from: NSNumber(value: wan)) ?? "0")萬)"
    }

}

#Preview {
    NavigationView {
        AssetDistributionView()
            .environmentObject(AssetManager())
    }
}
