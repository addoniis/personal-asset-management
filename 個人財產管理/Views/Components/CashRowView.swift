import SwiftUI

struct CashRowView: View {
    let asset: Asset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.body)
                if !asset.note.isEmpty {
                    Text(asset.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(formatCurrencyAsInteger(asset.value))
                .foregroundColor(.primary)
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
    CashRowView(asset: Asset(id: UUID(), category: .cash, name: "台幣現金", value: 100000, note: "備用金"))
}
