import SwiftUI

struct InsuranceView: View {
    @EnvironmentObject var assetManager: AssetManager

    private var insuranceAssets: [Asset] {
        assetManager.assets(for: .insurance)
    }

    private var totalInsuranceValue: Double {
        insuranceAssets.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        NavigationStack {
            List {
                TotalAssetsHeaderView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section(header: Text("保險資產總覽")) {
                    HStack {
                        Text("保險總價值")
                        Spacer()
                        Text(formatCurrencyAsInteger(totalInsuranceValue))
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("保險明細")) {
                    if insuranceAssets.isEmpty {
                        Text("尚無保險資料")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(insuranceAssets) { asset in
                            InsuranceRowView(asset: asset)
                        }
                    }
                }
            }
            .navigationTitle("保險資產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add insurance
                    }) {
                        Image(systemName: "plus")
                    }
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
}

struct InsuranceRowView: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrencyAsInteger(asset.value))
                    .foregroundColor(.blue)
            }

            if let note = asset.additionalInfo["notes"]?.string, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }
}

#Preview {
    InsuranceView()
        .environmentObject(AssetManager.shared)
}
