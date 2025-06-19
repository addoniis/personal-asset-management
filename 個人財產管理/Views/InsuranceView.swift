import SwiftUI

struct InsuranceView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil // 用於觸發編輯彈出視窗

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
                            insuranceRowView(asset: asset)
                                // MARK: - 添加這兩行以允許點擊編輯
                                .contentShape(Rectangle()) // 使整個行可點擊
                                .onTapGesture {
                                    selectedAsset = asset // 點擊時設定 selectedAsset
                                }
                        }
                    }
                }
            }
            .navigationTitle("保險資產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    insuranceEditView(mode: .add, initialAsset: nil)
                }
            }
            // 這個 sheet 會在 selectedAsset 被設定時彈出，用於編輯
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    insuranceEditView(mode: .edit, initialAsset: asset)
                }
            }
        }
    }
}

struct insuranceRowView: View {
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

            // 注意：您這裡檢查的是 additionalInfo["notes"]，而不是 "note"。
            // 請確認您的 CSV Importer 或其他地方儲存的是 "notes" 還是 "note"。
            // 如果是 "note"，這裡也需要改成 "note"。
            if let note = asset.additionalInfo["notes"]?.string, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct insuranceEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager

    let mode: AssetEditMode
    let initialAsset: Asset?

    @State private var name: String = ""
    @State private var value: String = ""
    @State private var insuranceValue: String = ""
    @State private var note: String = "" // 這個是編輯頁面綁定的 note
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text("基本資訊")) {
                TextField("名稱", text: $name)
                TextField("價值", text: $insuranceValue)
                    .keyboardType(.numberPad)
            }
            Section(header: Text("備註")) {
                TextField("備註", text: $note)
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
        .navigationTitle(mode == .add ? "新增保險" : "編輯保險")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    saveInsurance()
                }
                .disabled(name.isEmpty || insuranceValue.isEmpty)
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteInsurance()
            }
        } message: {
            Text("確定要刪除這個保險嗎？此操作無法撤銷。")
        }
        .onAppear {
            if let asset = initialAsset {
                name = asset.name
                insuranceValue = String(format: "%.0f", asset.value)
                // MARK: - 這裡也要注意 "note" 的鍵名
                note = asset.additionalInfo["note"]?.string ?? "" // 使用 "note" 而不是 "notes"
            }
        }
    }

    private func saveInsurance() {
        guard let insuranceValueNum = Double(insuranceValue) else { return }
        
        // MARK: - 儲存時使用 "note"
        let insuranceAdditionalInfo: [String: AdditionalInfoValue] = [
            "note": .string(note) // 確保這裡使用 "note"
        ]
        
        let insuranceAsset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: .insurance,
            name: name,
            value: insuranceValueNum,
            currency: .twd, // 如果保險有幣別，請確保從UI獲取或給定預設值
            additionalInfo: insuranceAdditionalInfo,
            createdAt: initialAsset?.createdAt ?? Date(),
            updatedAt: Date()
        )
        if mode == .add {
            assetManager.addAsset(insuranceAsset)
        } else {
            assetManager.updateAsset(insuranceAsset)
        }
        dismiss()
    }
        
    private func deleteInsurance() {
        if let assetToDelete = initialAsset {
            assetManager.deleteAsset(assetToDelete)

            // 這段 for associatedInsurance 的代碼看起來有問題，
            // 因為保險通常不會有 "associatedInsuranceId" 來關聯另一個保險。
            // 通常保險是一個獨立的資產，如果刪除它本身就夠了。
            // 我會將其註釋掉，如果您有特殊的關聯邏輯請再說明。
            /*
            if let associatedInsurance = assetManager.assets(for: .insurance).first(where: {
                $0.additionalInfo["associatedInsuranceId"]?.string == assetToDelete.id.uuidString
            }) {
                assetManager.deleteAsset(associatedInsurance)
            }
            */
        }
        dismiss()
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


#Preview {
    InsuranceView()
        .environmentObject(AssetManager.shared)
}
