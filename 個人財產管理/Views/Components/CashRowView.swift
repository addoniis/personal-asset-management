import SwiftUI

struct CashRowView: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrency(asset.value, currency: asset.additionalInfo["currency"]?.string ?? "TWD"))
                    .foregroundColor(.blue)
            }

            if let note = asset.additionalInfo["note"]?.string, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double, currency: String) -> String {
        guard let currencyType = Currency(rawValue: currency) else {
            return formatTWD(value)
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currencyType.locale)
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"

        if currency == "TWD" {
            return formatted.replacingOccurrences(of: "$", with: "NT$")
        }
        return formatted
    }

    private func formatTWD(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }
}

#Preview {
    CashRowView(asset: Asset(id: UUID(), category: .cash, name: "台幣現金", value: 100000, additionalInfo: ["note": .string("備用金"), "currency": .string("TWD")]))
}
