import SwiftUI

struct AssetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetManager = AssetManager.shared
    @State private var assetName: String
    @State private var amount: String
    @State private var category: AssetCategory
    @State private var date: Date
    @State private var notes: String
    @State private var showingDeleteAlert = false

    let asset: Asset
    let onDelete: () -> Void

    init(asset: Asset, onDelete: @escaping () -> Void) {
        self.asset = asset
        self.onDelete = onDelete
        _assetName = State(initialValue: asset.name)
        _amount = State(initialValue: String(format: "%.2f", asset.value))
        _category = State(initialValue: asset.category)
        _date = State(initialValue: asset.createdAt)
        _notes = State(initialValue: asset.additionalInfo["notes"]?.string ?? "")
    }

    var body: some View {
        NavigationView {
            AssetInputForm(
                assetName: $assetName,
                amount: $amount,
                category: $category,
                date: $date,
                notes: $notes
            ) {
                if let amountValue = Double(amount) {
                    let updatedAsset = Asset(
                        id: asset.id,
                        category: category,
                        name: assetName,
                        value: amountValue,
                        additionalInfo: ["notes": .string(notes)],
                        createdAt: date,
                        updatedAt: Date()
                    )
                    assetManager.updateAsset(updatedAsset)
                    dismiss()
                }
            }
            .navigationTitle("編輯資產")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("確認刪除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("確定要刪除這個資產嗎？此操作無法撤銷。")
            }
        }
    }
}

#Preview {
    AssetEditView(
        asset: Asset(
            id: UUID(),
            category: .property,
            name: "測試資產",
            value: 1000000,
            additionalInfo: ["notes": .string("測試備註")],
            createdAt: Date(),
            updatedAt: Date()
        )
    ) { }
}
