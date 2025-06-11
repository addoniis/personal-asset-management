import SwiftUI

struct PropertyView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAddSheet = false
    @State private var selectedAsset: Asset? = nil

    private var propertyAssets: [Asset] {
        assetManager.assets(for: .property)
    }

    private var totalValue: Double {
        propertyAssets.reduce(0) { $0 + $1.value }
    }

    private var totalLoan: Double {
        assetManager.assets(for: .mortgage).reduce(0) { $0 + $1.value }
    }

    private var netValue: Double {
        totalValue - totalLoan
    }

    private var mortgageAssets: [Asset] {
        assetManager.assets(for: .mortgage)
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
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatCurrencyAsInteger(totalValue))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text("貸款總額")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatCurrencyAsInteger(totalLoan))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // 下排：淨值
                        VStack {
                            Text("淨資產")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(formatCurrencyAsInteger(netValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
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
                Section(header: Text("房貸清單")) {
                    ForEach(mortgageAssets) { asset in
                        MortgageRowView(asset: asset)
                    }
                }
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

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "$", with: "NT$") ?? "NT$0"
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

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
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

    private func formatCurrencyAsInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct PropertyEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var assetManager: AssetManager

    let mode: AssetEditMode
    let initialAsset: Asset?

    @State private var name: String = ""
    @State private var value: String = ""
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
                TextField("價值", text: $value)
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
                .disabled(name.isEmpty || value.isEmpty)
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
            if let asset = initialAsset {
                name = asset.name
                value = String(format: "%.0f", asset.value)
                location = asset.additionalInfo["location"]?.string ?? ""
                note = asset.additionalInfo["note"]?.string ?? ""

                if let loanAmountValue = asset.additionalInfo["loanAmount"]?.double {
                    hasLoan = true
                    loanAmount = String(format: "%.0f", loanAmountValue)
                    monthlyPayment = String(format: "%.0f", asset.additionalInfo["monthlyPayment"]?.double ?? 0)
                }
            }
        }
    }

    private func saveProperty() {
        guard let valueNum = Double(value) else { return }

        var additionalInfo: [String: AdditionalInfoValue] = [
            "location": .string(location),
            "note": .string(note)
        ]

        if hasLoan {
            if let loanAmountNum = Double(loanAmount) {
                additionalInfo["loanAmount"] = .double(loanAmountNum)
            }
            if let monthlyPaymentNum = Double(monthlyPayment) {
                additionalInfo["monthlyPayment"] = .double(monthlyPaymentNum)
            }
        }

        let asset = Asset(
            id: initialAsset?.id ?? UUID(),
            category: .property,
            name: name,
            value: valueNum,
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

    private func deleteProperty() {
        if let asset = initialAsset {
            assetManager.deleteAsset(asset)
        }
        dismiss()
    }
}

#Preview {
    PropertyView()
        .environmentObject(AssetManager.shared)
}
