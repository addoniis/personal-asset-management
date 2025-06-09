import SwiftUI

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
        ScrollView {
            VStack(spacing: 24) {
                // 總資產卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("總資產")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(formatAmount(assetManager.totalAssets))
                        .font(.system(size: 36, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)

                // 資產分布圓餅圖
                VStack(alignment: .leading, spacing: 16) {
                    Text("資產分布")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    AssetPieChartView(
                        data: AssetCategory.allCases.map { category in
                            (
                                category.rawValue,
                                assetManager.assetsByCategory[category] ?? 0,
                                category.color
                            )
                        },
                        total: assetManager.totalAssets
                    )
                    .frame(height: 280)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)

                // 詳細資產列表
                VStack(alignment: .leading, spacing: 16) {
                    Text("詳細資產")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(AssetCategory.allCases, id: \.self) { category in
                        let amount = assetManager.assetsByCategory[category] ?? 0
                        if amount > 0 {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)

                                Text(category.rawValue)

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text(formatAmount(amount))
                                        .font(.headline)

                                    Text(String(format: "%.1f%%", (amount / assetManager.totalAssets) * 100))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
            .padding()
        }
        .navigationTitle("資產分布")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationView {
        AssetDistributionView()
            .environmentObject(AssetManager())
    }
}
