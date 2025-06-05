import SwiftUI

enum AssetEditMode {
    case add
    case edit
}

struct AssetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetManager = AssetManager.shared
    @State private var assetName: String
    @State private var amount: String
    @State private var category: AssetCategory
    @State private var date: Date
    @State private var notes: String
    @State private var showingDeleteAlert = false

    let mode: AssetEditMode
    let initialAsset: Asset

    init(mode: AssetEditMode, initialAsset: Asset) {
        self.mode = mode
        self.initialAsset = initialAsset
        _assetName = State(initialValue: initialAsset.name)
        _amount = State(initialValue: String(format: "%.2f", initialAsset.value))
        _category = State(initialValue: initialAsset.category)
        _date = State(initialValue: initialAsset.createdAt)
        _notes = State(initialValue: initialAsset.additionalInfo["notes"]?.string ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("名稱", text: $assetName)
                TextField("金額", text: $amount)
                    .keyboardType(.decimalPad)
                if mode == .add {
                    Picker("類別", selection: $category) {
                        ForEach(AssetCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
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
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("刪除資產")
                            Spacer()
                        }
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

        let updatedAsset = Asset(
            id: mode == .add ? UUID() : initialAsset.id,
            category: category,
            name: assetName,
            value: amountValue,
            additionalInfo: ["notes": .string(notes)],
            createdAt: mode == .add ? date : initialAsset.createdAt,
            updatedAt: Date()
        )

        if mode == .add {
            assetManager.addAsset(updatedAsset)
        } else {
            assetManager.updateAsset(updatedAsset)
        }

        dismiss()
    }

    private func deleteAsset() {
        assetManager.deleteAsset(initialAsset)
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
                additionalInfo: ["notes": .string("測試備註")],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
