import SwiftUI

struct CaseView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil

    private var cashAssets: [Asset] {
        assetManager.assets(for: .cash)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("現金資產總覽")) {
                    HStack {
                        Text("總金額")
                        Spacer()
                        Text(formatCurrency(assetManager.totalValue(for: .cash)))
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("現金明細")) {
                    ForEach(cashAssets) { asset in
                        AssetRowView(asset: asset)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAsset = asset
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
                    AssetEditView(
                        mode: .add,
                        initialAsset: Asset(
                            category: .cash,
                            name: "",
                            value: 0,
                            additionalInfo: [:],
                            createdAt: Date()
                        )
                    )
                }
            }
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    AssetEditView(
                        mode: .edit,
                        initialAsset: asset
                    )
                }
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrency(asset.value))
                    .foregroundColor(.blue)
            }

            if !asset.additionalInfo.isEmpty {
                ForEach(Array(asset.additionalInfo.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value.displayValue)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    CaseView()
        .environmentObject(AssetManager.shared)
}
