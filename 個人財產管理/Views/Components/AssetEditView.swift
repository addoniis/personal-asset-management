import SwiftUI

enum AssetEditMode {
    case add
    case edit
}

struct AssetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager
    @State private var assetName: String
    @State private var amount: String
    @State private var category: AssetCategory
    @State private var date: Date
    @State private var notes: String
    @State private var showingDeleteAlert = false

    let mode: AssetEditMode
    let initialAsset: Asset?

    init(mode: AssetEditMode, initialAsset: Asset?) {
        self.mode = mode
        self.initialAsset = initialAsset
        _assetName = State(initialValue: initialAsset?.name ?? "")
        _amount = State(initialValue: initialAsset?.value != nil ? String(format: "%.0f", initialAsset!.value) : "")
        _category = State(initialValue: initialAsset?.category ?? .cash)
        _date = State(initialValue: initialAsset?.createdAt ?? Date())
        _notes = State(initialValue: initialAsset?.note ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("基本資訊")) {
                TextField("名稱", text: $assetName)
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

            if mode == .edit {
                Section {
                    Button("刪除資產", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .navigationTitle(mode == .add ? "新增資產" : "編輯資產")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    saveAsset()
                }
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteAsset()
            }
        } message: {
            Text("確定要刪除這個資產嗎？此操作無法撤銷。")
        }
    }

    private func saveAsset() {
        guard let amountValue = Double(amount) else { return }

        let finalValue: Double
        if category == .cash {
            finalValue = floor(amountValue)
        } else {
            finalValue = amountValue
        }

        let asset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: category,
            name: assetName,
            value: finalValue,
            note: notes,
            createdAt: initialAsset?.createdAt ?? date
        )

        if mode == .add {
            assetManager.addAsset(asset)
        } else {
            assetManager.updateAsset(asset)
        }

        dismiss()
    }

    private func deleteAsset() {
        if let asset = initialAsset {
            assetManager.deleteAsset(asset)
        }
        dismiss()
    }
}

#Preview {
    NavigationView {
        AssetEditView(
            mode: .add,
            initialAsset: Asset(
                id: UUID(),
                category: .property,
                name: "測試資產",
                value: 1000000,
                note: "測試備註",
                additionalInfo: [:],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
