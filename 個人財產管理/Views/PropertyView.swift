import SwiftUI

struct PropertyView: View {
    @StateObject private var assetManager = AssetManager.shared
    @State private var showingAddProperty = false

    private var propertyAssets: [Asset] {
        assetManager.assets.filter { $0.category == .property }
    }

    private var totalPropertyValue: Double {
        propertyAssets.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 總房地產資產卡片
                    AssetCardView(
                        title: "總房地產資產",
                        amount: totalPropertyValue,
                        trend: assetManager.getGrowthRate(for: .property),
                        color: AssetCategory.property.color
                    )
                    .padding(.horizontal)

                    // 房地產資產趨勢
                    AssetTrendChartView(
                        data: assetManager.getAssetHistory(for: .property, months: 12).map { history in
                            AssetTrendChartView.DataPoint(
                                date: history.date,
                                value: history.totalValue
                            )
                        },
                        title: "房地產資產趨勢"
                    )
                    .padding(.horizontal)

                    // 房地產列表
                    LazyVStack(spacing: 16) {
                        ForEach(propertyAssets) { property in
                            PropertyCard(property: property)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("房地產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProperty = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
            }
        }
    }
}

// 房地產卡片視圖
struct PropertyCard: View {
    let property: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(property.name)
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("當前價值")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", property.amount))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if !property.notes.isEmpty {
                    Text(property.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// 新增房地產視圖
struct AddPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetManager = AssetManager.shared
    @State private var propertyName = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationView {
            AssetInputForm(
                assetName: $propertyName,
                amount: $amount,
                category: .constant(.property),
                date: $date,
                notes: $notes
            ) {
                if let amountValue = Double(amount) {
                    let property = Asset(
                        id: UUID(),
                        name: propertyName,
                        amount: amountValue,
                        category: .property,
                        date: date,
                        notes: notes
                    )
                    assetManager.addAsset(property)
                    dismiss()
                }
            }
            .navigationTitle("新增房地產")
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
    PropertyView()
}
