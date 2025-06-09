import SwiftUI

struct CashEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager

    let mode: AssetEditMode
    let initialAsset: Asset?

    @State private var assetName: String = ""
    @State private var amount: String = ""
    @State private var currency: Currency = .twd
    @State private var note: String = ""
    @State private var showingDeleteAlert = false

    init(mode: AssetEditMode, initialAsset: Asset?) {
        self.mode = mode
        self.initialAsset = initialAsset

        _assetName = State(initialValue: initialAsset?.name ?? "")
        _amount = State(initialValue: initialAsset?.value != nil ? String(format: "%.0f", initialAsset!.value) : "")
        _currency = State(initialValue: Currency(rawValue: initialAsset?.additionalInfo["currency"]?.string ?? "TWD") ?? .twd)
        _note = State(initialValue: initialAsset?.additionalInfo["note"]?.string ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("基本資訊")) {
                TextField("名稱", text: $assetName)
                TextField("金額", text: $amount)
                    .keyboardType(.numberPad)
                Picker("幣別", selection: $currency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text(currency.displayName).tag(currency)
                    }
                }
            }

            Section(header: Text("備註")) {
                TextEditor(text: $note)
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
        .navigationTitle(mode == .add ? "新增現金" : "編輯現金")
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

        var additionalInfo: [String: AdditionalInfoValue] = [:]
        additionalInfo["currency"] = .string(currency.rawValue)
        if !note.isEmpty {
            additionalInfo["note"] = .string(note)
        }

        let asset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: .cash,
            name: assetName,
            value: floor(amountValue),
            additionalInfo: additionalInfo,
            createdAt: initialAsset?.createdAt ?? Date(),
            updatedAt: Date()
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
        CashEditView(
            mode: .add,
            initialAsset: Asset(
                id: UUID(),
                category: .cash,
                name: "測試現金",
                value: 10000,
                additionalInfo: [
                    "currency": .string("TWD"),
                    "note": .string("測試備註")
                ]
            )
        )
        .environmentObject(AssetManager.shared)
    }
}
