import SwiftUI

struct AssetInputForm: View {
    @Binding var assetName: String
    @Binding var amount: String
    @Binding var category: AssetCategory
    @Binding var date: Date
    @Binding var notes: String

    let onSubmit: () -> Void

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = category == .stock ? 2 : 0
        formatter.minimumFractionDigits = category == .stock ? 2 : 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
    }

    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("資產名稱", text: $assetName)
                TextField("金額", text: $amount)
                    .keyboardType(category == .cash ? .numberPad : .decimalPad)
                Picker("類別", selection: $category) {
                    ForEach(AssetCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                DatePicker("日期", selection: $date, displayedComponents: .date)
            }

            Section(header: Text("備註")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }

            Section {
                Button(action: onSubmit) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct AssetInputFormPreview: View {
    @State private var assetName = ""
    @State private var amount = ""
    @State private var category = AssetCategory.cash
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        AssetInputForm(
            assetName: $assetName,
            amount: $amount,
            category: $category,
            date: $date,
            notes: $notes,
            onSubmit: {}
        )
    }
}

#Preview {
    AssetInputFormPreview()
}
