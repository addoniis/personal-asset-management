import SwiftUI

struct PropertyView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil

    var propertyAssets: [Asset] {
        assetManager.assets(for: .property)
    }

   var mortgageAssets: [Asset] {
        assetManager.assets(for: .mortgage)
    }

    //計算不動產總值 totalValue
    var totalValue: Double {
        propertyAssets.reduce(0) { $0 + $1.value }
    }
    
    //計算貸款總值 totalLoan
    var totalLoan: Double {
        mortgageAssets.reduce(0) { $0 + $1.value }
    }
    
    //計算不動產淨值 netValue
    var netValue: Double {
        totalValue - totalLoan
    }


    var body: some View {
        NavigationStack {
            List {
                TotalAssetsHeaderView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section(header: Text("不動產資產總覽")) {
                    // 總覽區域
                    VStack(spacing: 16) {
                        HStack {
                            Text("不動產總覽")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 上排：總值和貸款
                        HStack(spacing: 20) {
                            VStack {
                                Text("不動產總值")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 3)
                                Text(formatCurrencyAsInteger(totalValue))
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text("貸款總額")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 3)
                                Text(formatCurrencyAsInteger(totalLoan))
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // 下排：淨值
                        VStack {
                            Text("淨資產")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Text(formatCurrencyAsInteger(netValue))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 0)  //與上方的距離
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }

                // === 房產清單 ===
                Section(header: Text("房產清單")) {
                    ForEach(propertyAssets) { asset in
                        PropertyRowView(asset: asset)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAsset = asset
                            }
                    }
                }

                // === 房貸清單 ===
//                Section(header: Text("房貸清單")) {
//                    ForEach(mortgageAssets) { mortagage in
//                        MortgageRowView(asset: mortagage)
//                    }
//                }
            }
            .navigationTitle("不動產資產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    PropertyEditView(mode: .add, initialAsset: nil)
                }
            }
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    PropertyEditView(mode: .edit, initialAsset: asset)
                }
            }
        }
    }
}

struct PropertyRowView: View {
    let asset: Asset

    private var loanAmount: Double {
        asset.additionalInfo["loanAmount"]?.double ?? 0
    }

    private var monthlyPayment: Double {
        asset.additionalInfo["monthlyPayment"]?.double ?? 0
    }

    private var netValue: Double {
        asset.value - loanAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrencyAsInteger(asset.value))
                    .foregroundColor(.blue)
            }

            if let location = asset.additionalInfo["location"]?.string {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if loanAmount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("貸款餘額：")
                        Text(formatCurrencyAsInteger(loanAmount))
                            .foregroundColor(.red)
                    }
                    .font(.subheadline)

                    HStack {
                        Text("月付金額：")
                        Text(formatCurrencyAsInteger(monthlyPayment))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    HStack {
                        Text("淨值：")
                        Text(formatCurrencyAsInteger(netValue))
                            .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                }
            }

            if let note = asset.additionalInfo["note"]?.string, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

}


struct MortgageRowView: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrencyAsInteger(asset.value))
                    .foregroundColor(.red)
            }
            if let rate = asset.additionalInfo["rate"]?.double {
                Text("利率：\(String(format: "%.2f", rate))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let note = asset.additionalInfo["note"]?.string, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

//    private func formatCurrencyAsInteger(_ value: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = Locale(identifier: "zh_TW")
//        formatter.maximumFractionDigits = 0
//        return formatter.string(from: NSNumber(value: value)) ?? "$0"
//    }
}

struct PropertyEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager

    let mode: AssetEditMode
    let initialAsset: Asset?

    @State private var name: String = ""
    @State private var value: String = ""
    @State private var propertyValue: String = ""
    @State private var location: String = ""
    @State private var note: String = ""
    @State private var hasLoan: Bool = false
    @State private var loanAmount: String = ""
    @State private var monthlyPayment: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text("基本資訊")) {
                TextField("名稱", text: $name)
                TextField("價值", text: $propertyValue)
                    .keyboardType(.numberPad)
                TextField("地址", text: $location)
            }
            
            Section(header: Text("貸款資訊")) {
                Toggle("有房貸", isOn: $hasLoan)
                
                if hasLoan {
                    TextField("貸款餘額", text: $loanAmount)
                        .keyboardType(.numberPad)
                    TextField("月付金額", text: $monthlyPayment)
                        .keyboardType(.numberPad)
                }
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
        .navigationTitle(mode == .add ? "新增不動產" : "編輯不動產")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    saveProperty()
                }
                .disabled(name.isEmpty || propertyValue.isEmpty)
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteProperty()
            }
        } message: {
            Text("確定要刪除這個不動產嗎？此操作無法撤銷。")
        }
        .onAppear {
            // 當 View 首次出現在螢幕上時，執行這個閉包內的程式碼
            if let asset = initialAsset {
                name = asset.name
                propertyValue = String(format: "%.0f", asset.value)
                location = asset.additionalInfo["location"]?.string ?? ""
                note = asset.additionalInfo["note"]?.string ?? ""

                // 查找與此房產相關聯的貸款資產
                if let associatedMortgage = assetManager.assets(for: .mortgage).first(where: {
                    $0.additionalInfo["associatedPropertyId"]?.string == asset.id.uuidString
                }) {
                    hasLoan = true
                    // 貸款金額現在從 mortgage asset 的 value 中獲取
                    loanAmount = String(format: "%.0f", associatedMortgage.value)
                    // 月付金額從 mortgage asset 的 additionalInfo 中獲取
                    monthlyPayment = String(format: "%.0f", associatedMortgage.additionalInfo["monthlyPayment"]?.double ?? 0)
                } else {
                    // 如果沒有找到相關聯的貸款，則重置貸款相關的狀態
                    hasLoan = false
                    loanAmount = ""
                    monthlyPayment = ""
                }
            }
        }
    }

    private func saveProperty() {
        guard let propertyValueNum = Double(propertyValue) else { return }
        guard let loanAmountNum = Double(loanAmount) else { return }
        guard let monthlyPaymentNum = Double(monthlyPayment) else { return }
        
        var propertyAdditionalInfo: [String: AdditionalInfoValue] = [
            "location": .string(location),
            "note": .string(note)
        ]

        if hasLoan {
            if let loanAmountNum = Double(loanAmount) {
                propertyAdditionalInfo["loanAmount"] = .double(loanAmountNum)
            }
            if let monthlyPaymentNum = Double(monthlyPayment) {
                propertyAdditionalInfo["monthlyPayment"] = .double(monthlyPaymentNum)
            }
        }

        let propertyAsset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: .property,
            name: name,
            value: propertyValueNum,
            additionalInfo: propertyAdditionalInfo,
            createdAt: initialAsset?.createdAt ?? Date(),
            updatedAt: Date()
        )
        if mode == .add {
            assetManager.addAsset(propertyAsset)
        } else {
            assetManager.updateAsset(propertyAsset)
        }
        
        
        // ====== 處理房貸資產 ======
        if hasLoan {
            var mortgageAdditionalInfo: [String: AdditionalInfoValue] = [
                "associatedPropertyId": .string(propertyAsset.id.uuidString) // 將貸款與房產關聯起來
            ]
            if !note.isEmpty {
                mortgageAdditionalInfo["note"] = .string(note) // 貸款備註
            }
            // 您可以根據需要添加其他貸款相關的 additionalInfo，例如利率、貸款期限等
            mortgageAdditionalInfo["loanAmount"] = .double(loanAmountNum) // 實際貸款餘額
            mortgageAdditionalInfo["monthlyPayment"] = .double(monthlyPaymentNum)// 月付金額

            // 檢查是否已經存在與此房產相關聯的 mortgage 資產，以便更新
            // 這需要 AssetManager 中提供一個方法來查找或更新相關貸款
            // 如果 initialAsset 是房產，我們需要找到其對應的貸款資產ID
            let existingMortgageAsset = assetManager.assets(for: .mortgage).first {
                $0.additionalInfo["associatedPropertyId"]?.string == propertyAsset.id.uuidString
            }

            let mortgageAsset = Asset(
                id: existingMortgageAsset?.id ?? UUID(), // 如果存在則更新，否則創建新ID
                category: .mortgage, // 這是貸款的資產類別
                name: "\(name) 房貸", // 給貸款一個描述性名稱
                value: loanAmountNum, // 貸款資產的值就是貸款金額 (負數表示負債)
                additionalInfo: mortgageAdditionalInfo,
                createdAt: existingMortgageAsset?.createdAt ?? Date(),
            )

            if existingMortgageAsset != nil {
                assetManager.updateAsset(mortgageAsset)
            } else {
                assetManager.addAsset(mortgageAsset)
            }
        } else {
            // 如果 hasLoan 變成 false，並且之前有貸款，則刪除相關的 mortgage 資產
            if let existingMortgageAsset = assetManager.assets(for: .mortgage).first(where: {
                $0.additionalInfo["associatedPropertyId"]?.string == propertyAsset.id.uuidString
            }) {
                assetManager.deleteAsset(existingMortgageAsset)
            }
        }

//        if mode == .add {
//            assetManager.addAsset(mortagage)
////            assetManager.addAsset(mortagage)  //adonis 6/18
//        } else {
//            assetManager.updateAsset(mortagage)
//        }

        dismiss()
    }

    private func deleteProperty() {
        if let assetToDelete = initialAsset {
            // 刪除房產資產
            assetManager.deleteAsset(assetToDelete)

            // 同時刪除與該房產相關聯的貸款資產
            if let associatedMortgage = assetManager.assets(for: .mortgage).first(where: {
                $0.additionalInfo["associatedPropertyId"]?.string == assetToDelete.id.uuidString
            }) {
                assetManager.deleteAsset(associatedMortgage)
            }
        }
        dismiss()
    }
}


private func formatCurrencyAsInteger(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "zh_TW")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "$0"
}


#Preview {
    PropertyView()
        .environmentObject(AssetManager.shared)
}
