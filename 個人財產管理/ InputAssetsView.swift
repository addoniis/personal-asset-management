import SwiftUI

struct InputAssetsView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var assets: [Asset] = []
    @State private var selectedCategory = "現金"
    let categories = ["現金", "股票", "儲蓄險", "房產", "房貸"]
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

    var headerView: some View {
        VStack {
            Text("輸入您的現有財產")
                .font(.headline)
                .padding()

            Picker("資產類別", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var inputFields: some View {
        if selectedCategory == "現金" {
            TextField("銀行名稱", text: $bankName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("存款總額", text: $cashAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        } else if selectedCategory == "股票" {
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
        } else if selectedCategory == "儲蓄險" {
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
        } else if selectedCategory == "房產" {
            TextField("房屋地址", text: $propertyAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("房屋現值", text: $propertyValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
        } else if selectedCategory == "房貸" {
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
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                headerView // 使用子視圖
                inputFields // 使用子視圖

                Button("新增資產") {
                    addAsset()
                }
                .padding()
                .disabled(isAddButtonDisabled)

                List {
                    ForEach(assets, id: \.id) { asset in
                        HStack {
                            Text("\(asset.category): \(asset.name)")
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
            }
            .navigationTitle("輸入財產")
        }
    }

    // 這些函數和屬性定義在 body 屬性之外，但在 struct 的內部
    var isAddButtonDisabled: Bool {
        // ... 實作
        return false
    }

    func addAsset() {
         var additionalInfo: [String: AdditionalInfoValue] = [:]
         var assetName = ""
         var assetValue: Double = 0

         switch selectedCategory {
         case "現金":
             assetName = bankName
             if let value = Double(cashAmount) {
                 assetValue = value
                 additionalInfo["bank"] = .string(bankName)
                 additionalInfo["amount"] = .double(value)
                 bankName = "" // 清空輸入框
                 cashAmount = "" // 清空輸入框
             }
         case "股票":
             assetName = "\(stockMarket) \(stockCode)"
             if let shares = Int(stockShares) {
                 additionalInfo["market"] = .string(stockMarket)
                 additionalInfo["code"] = .string(stockCode)
                 additionalInfo["shares"] = .integer(shares)
                 assetValue = 0 // 股票價值通常需要從外部獲取，這裡先設為 0
                 stockCode = "" // 清空輸入框
                 stockShares = "" // 清空輸入框
             }
         case "儲蓄險":
             assetName = policyNumber // 使用保單號碼作為名稱
             if let value = Double(insuranceValue) {
                 assetValue = value
                 additionalInfo["company"] = .string(insuranceCompany)
                 additionalInfo["policyNumber"] = .string(policyNumber)
                 additionalInfo["value"] = .double(value)
                 insuranceCompany = "" // 清空輸入框
                 policyNumber = "" // 清空輸入框
                 insuranceValue = "" // 清空輸入框
             }
         case "房產":
             assetName = propertyAddress
             if let value = Double(propertyValue) {
                 assetValue = value
                 additionalInfo["address"] = .string(propertyAddress)
                 additionalInfo["value"] = .double(value)
                 propertyAddress = "" // 清空輸入框
                 propertyValue = "" // 清空輸入框
             }
         case "房貸":
             assetName = mortgageBank // 使用貸款銀行作為名稱
             if let balance = Double(mortgageBalance), let rate = Double(mortgageRate) {
                 assetValue = -balance // 房貸是負債，用負數表示
                 additionalInfo["bank"] = .string(mortgageBank)
                 additionalInfo["balance"] = .double(balance)
                 additionalInfo["rate"] = .double(rate)
                 mortgageBank = "" // 清空輸入框
                 mortgageBalance = "" // 清空輸入框
                 mortgageRate = "" // 清空輸入框
             }
         default:
             return
         }

         let newAsset = Asset(category: selectedCategory, name: assetName, value: assetValue, additionalInfo: additionalInfo)
         assets.append(newAsset) // 將新創建的 Asset 添加到 assets 陣列中
     }
    func deleteAsset(at offsets: IndexSet) {
        // ... 實作
    }

    func assetDescription(for asset: Asset) -> String {
        // ... 實作
        return ""
    }

    func saveAssets() {
        // ... 實作
    }

    func loadAssets() {
        // ... 實作
    }
}

#Preview {
    InputAssetsView()
}
