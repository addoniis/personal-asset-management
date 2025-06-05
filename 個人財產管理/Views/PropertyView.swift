import SwiftUI

struct PropertyView: View {
    @EnvironmentObject private var assetManager: AssetManager
    @State private var showingAddProperty = false

    private var propertyAssets: [Asset] {
        assetManager.assets(for: .property)
    }

    private var totalPropertyValue: Double {
        assetManager.totalValue(for: .property)
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
                        color: AssetCategory.property.displayColor
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
                    .environmentObject(assetManager)
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
                    Text("$\(String(format: "%.2f", property.value))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if let notes = property.additionalInfo["notes"]?.string {
                    Text(notes)
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
    @EnvironmentObject private var assetManager: AssetManager
    @State private var propertyName = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("名稱", text: $propertyName)
                    TextField("價值", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section(header: Text("備註")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    Button("儲存") {
                        if let amountValue = Double(amount) {
                            let property = Asset(
                                id: UUID(),
                                category: .property,
                                name: propertyName,
                                value: amountValue,
                                additionalInfo: ["notes": .string(notes)],
                                createdAt: date,
                                updatedAt: date
                            )
                            assetManager.addAsset(property)
                            dismiss()
                        }
                    }
                    .disabled(propertyName.isEmpty || amount.isEmpty)
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
        .environmentObject(AssetManager.shared)
}
