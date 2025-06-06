import SwiftUI

struct AssetInputForm: View {
    @Binding var assetName: String
    @Binding var amount: String
    @Binding var category: AssetCategory
    @Binding var date: Date
    @Binding var notes: String

    let onSubmit: () -> Void

    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("資產名稱", text: $assetName)
                TextField("金額", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("類別", selection: $category) {
                    ForEach(AssetCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
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

#Preview {
    @State var assetName = ""
    @State var amount = ""
    @State var category = AssetCategory.cash
    @State var date = Date()
    @State var notes = ""

    return AssetInputForm(
        assetName: $assetName,
        amount: $amount,
        category: $category,
        date: $date,
        notes: $notes,
        onSubmit: {}
    )
}
