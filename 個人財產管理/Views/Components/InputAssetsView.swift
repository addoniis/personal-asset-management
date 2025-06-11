import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct InputAssetsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assetManager = AssetManager.shared
    @State private var assets: [Asset] = []
    @State private var selectedCategory: AssetCategory = .cash
    let categories: [AssetCategory] = [.cash, .stock, .fund, .insurance, .property, .mortgage, .other]

    // 現金相關輸入
    @State private var bankName = ""
    @State private var cashAmount = ""

    // 股票相關輸入
    @State private var stockMarket = "台股"
    let stockMarkets = ["台股", "美股"]
    @State private var stockCode = ""
    @State private var stockShares = ""

    // 房產相關輸入
    @State private var propertyAddress = ""
    @State private var propertyValue = ""

    // 儲蓄險相關輸入
    @State private var insuranceCompany = ""
    @State private var policyNumber = ""
    @State private var insuranceValue = ""

    // 房貸相關輸入
    @State private var mortgageBank = ""
    @State private var mortgageBalance = ""
    @State private var mortgageRate = ""

    @State private var showDocumentPicker = false
    @State private var parsedAssets: [Asset] = []
    @State private var showReview = false
    @State private var importError: String?

    var headerView: some View {
        VStack {
            Text("輸入您的現有財產")
                .font(.headline)
                .padding()

            Picker("資產類別", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category.displayName)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var inputFields: some View {
        switch selectedCategory {
        case .cash:
            TextField("銀行名稱", text: $bankName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("存款總額", text: $cashAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        case .stock:
            Picker("市場", selection: $stockMarket) {
                ForEach(stockMarkets, id: \.self) { market in
                    Text(market)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            TextField("股票代碼", text: $stockCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("股數", text: $stockShares)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)
        case .insurance:
            TextField("保險公司", text: $insuranceCompany)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("保單號碼", text: $policyNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("現有價值", text: $insuranceValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        case .property:
            TextField("房屋地址", text: $propertyAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("房屋現值", text: $propertyValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        case .mortgage:
            TextField("貸款銀行", text: $mortgageBank)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("貸款餘額", text: $mortgageBalance)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
            TextField("利率", text: $mortgageRate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        case .fund:
            TextField("基金名稱", text: $bankName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("投資金額", text: $cashAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        case .other:
            TextField("資產名稱", text: $bankName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("資產價值", text: $cashAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                headerView
                inputFields

                Button("新增資產") {
                    addAsset()
                }
                .padding()
                .disabled(isAddButtonDisabled)

                List {
                    ForEach(assets, id: \.id) { asset in
                        HStack {
                            Text("\(asset.category.displayName): \(asset.name)")
                            Spacer()
                            Text(assetDescription(for: asset))
                        }
                    }
                    .onDelete(perform: deleteAsset)
                }

                HStack {
                    Button("儲存資產") {
                        saveAssets()
                    }
                    .padding()

                    Button("讀取資產") {
                        loadAssets()
                    }
                    .padding()
                }

                Spacer()

                // === CSV 匯入區塊 ===
                Divider()
                Button("匯入 CSV 檔案") {
                    showDocumentPicker = true
                }
                .fileImporter(
                    isPresented: $showDocumentPicker,
                    allowedContentTypes: [UTType.commaSeparatedText, UTType.text],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first, let data = try? Data(contentsOf: url), let csvString = String(data: data, encoding: .utf8) {
                            parsedAssets = CSVImporter.importAssets(from: csvString)
                            if parsedAssets.isEmpty {
                                importError = "CSV 解析失敗或無有效資料"
                            } else {
                                importError = nil
                                showReview = true
                            }
                        } else {
                            importError = "無法讀取檔案內容"
                        }
                    case .failure(let error):
                        importError = "檔案選擇失敗：\(error.localizedDescription)"
                    }
                }

                if let importError = importError {
                    Text(importError)
                        .foregroundColor(.red)
                }

                if showReview {
                    List(parsedAssets) { asset in
                        VStack(alignment: .leading) {
                            Text(asset.name)
                            Text("類別：\(asset.category.displayName)")
                            Text("金額：\(asset.value)")
                        }
                    }
                    .frame(height: 300)

                    Button("確認導入") {
                        for asset in parsedAssets {
                            assetManager.addAsset(asset)
                        }
                        showReview = false
                        parsedAssets = []
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("輸入財產")
        }
    }

    var isAddButtonDisabled: Bool {
        switch selectedCategory {
        case .cash:
            return bankName.isEmpty || cashAmount.isEmpty
        case .stock:
            return stockCode.isEmpty || stockShares.isEmpty
        case .insurance:
            return insuranceCompany.isEmpty || policyNumber.isEmpty || insuranceValue.isEmpty
        case .property:
            return propertyAddress.isEmpty || propertyValue.isEmpty
        case .mortgage:
            return mortgageBank.isEmpty || mortgageBalance.isEmpty || mortgageRate.isEmpty
        case .fund:
            return bankName.isEmpty || cashAmount.isEmpty
        case .other:
            return bankName.isEmpty || cashAmount.isEmpty
        }
    }

    func addAsset() {
        var additionalInfo: [String: AdditionalInfoValue] = [:]
        var assetName = ""
        var assetValue: Double = 0

        switch selectedCategory {
        case .cash:
            assetName = bankName
            if let value = Double(cashAmount) {
                assetValue = value
                additionalInfo["bank"] = .string(bankName)
                additionalInfo["amount"] = .double(value)
                bankName = ""
                cashAmount = ""
            }
        case .stock:
            assetName = "\(stockMarket) \(stockCode)"
            if let shares = Int(stockShares) {
                additionalInfo["market"] = .string(stockMarket)
                additionalInfo["code"] = .string(stockCode)
                additionalInfo["shares"] = .integer(shares)
                assetValue = 0
                stockCode = ""
                stockShares = ""
            }
        case .insurance:
            assetName = policyNumber
            if let value = Double(insuranceValue) {
                assetValue = value
                additionalInfo["company"] = .string(insuranceCompany)
                additionalInfo["policyNumber"] = .string(policyNumber)
                additionalInfo["value"] = .double(value)
                insuranceCompany = ""
                policyNumber = ""
                insuranceValue = ""
            }
        case .property:
            assetName = propertyAddress
            if let value = Double(propertyValue) {
                assetValue = value
                additionalInfo["address"] = .string(propertyAddress)
                additionalInfo["value"] = .double(value)
                propertyAddress = ""
                propertyValue = ""
            }
        case .mortgage:
            assetName = mortgageBank
            if let balance = Double(mortgageBalance), let rate = Double(mortgageRate) {
                assetValue = -balance
                additionalInfo["bank"] = .string(mortgageBank)
                additionalInfo["balance"] = .double(balance)
                additionalInfo["rate"] = .double(rate)
                mortgageBank = ""
                mortgageBalance = ""
                mortgageRate = ""
            }
        case .fund:
            assetName = bankName
            if let value = Double(cashAmount) {
                assetValue = value
                additionalInfo["name"] = .string(bankName)
                additionalInfo["amount"] = .double(value)
                bankName = ""
                cashAmount = ""
            }
        case .other:
            assetName = bankName
            if let value = Double(cashAmount) {
                assetValue = value
                additionalInfo["name"] = .string(bankName)
                additionalInfo["value"] = .double(value)
                bankName = ""
                cashAmount = ""
            }
        }

        if !assetName.isEmpty {
            let newAsset = Asset(
                category: selectedCategory,
                name: assetName,
                value: assetValue,
                additionalInfo: additionalInfo,
                createdAt: Date(),
                updatedAt: Date()
            )
            assetManager.addAsset(newAsset)
            assets = assetManager.assets
        }
    }

    func deleteAsset(at offsets: IndexSet) {
        for index in offsets {
            let asset = assets[index]
            assetManager.deleteAsset(asset)
        }
        assets = assetManager.assets
    }

    func assetDescription(for asset: Asset) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")

        return formatter.string(from: NSNumber(value: asset.value)) ?? ""
    }

    func saveAssets() {
        // 資產已經通過 AssetManager 自動保存
    }

    func loadAssets() {
        assets = assetManager.assets
    }
}

#Preview {
    InputAssetsView()
}
