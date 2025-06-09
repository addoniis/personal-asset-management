import Foundation

class CSVImporter {
    static func importAssets(from csvString: String) -> [Asset] {
        var assets: [Asset] = []
        let rows = csvString.components(separatedBy: .newlines)

        // 跳過標題行
        guard rows.count > 1 else { return [] }
        let dataRows = Array(rows.dropFirst())

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        for row in dataRows {
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 5 else { continue }

            // CSV格式: 類別,名稱,數量,建立於,備註
            let categoryStr = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let name = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let quantityStr = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let dateStr = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let note = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)

            // 處理日期
            let createdAt = dateFormatter.date(from: dateStr) ?? Date()

            // 根據類別處理數量和價值
            var category: AssetCategory
            var value: Double = 0
            var additionalInfo: [String: AdditionalInfoValue] = [:]

            switch categoryStr {
            case "現金":
                category = .cash
                guard let amount = Double(quantityStr) else { continue }
                value = amount

                // 從備註中解析幣別信息
                let currencyCode = note.contains("USD") ? "USD" :
                                 note.contains("JPY") ? "JPY" :
                                 note.contains("CNY") ? "CNY" :
                                 note.contains("EUR") ? "EUR" : "TWD"

                additionalInfo["currency"] = .string(currencyCode)
                value = amount

            case "台灣股票":
                category = .stock
                guard let shares = Double(quantityStr) else { continue }
                additionalInfo["isUSStock"] = .string("false")
                additionalInfo["shares"] = .string(String(format: "%.0f", shares))
                additionalInfo["symbol"] = .string(name)
                value = shares  // 暫時將股數設為value，之後會由StockService更新實際價值

            case "美國股票":
                category = .stock
                guard let shares = Double(quantityStr) else { continue }
                additionalInfo["isUSStock"] = .string("true")
                additionalInfo["shares"] = .string(String(format: "%.0f", shares))
                additionalInfo["symbol"] = .string(name)
                value = shares  // 暫時將股數設為value，之後會由StockService更新實際價值

            case "房產":
                category = .property
                guard let amount = Double(quantityStr) else { continue }
                value = amount

            case "房貸":
                category = .mortgage
                guard let amount = Double(quantityStr) else { continue }
                value = amount

            case "保險":
                category = .insurance
                guard let amount = Double(quantityStr) else { continue }
                value = amount

            default:
                continue
            }

            let asset = Asset(
                id: UUID(),
                category: category,
                name: name,
                value: value,
                note: note,
                additionalInfo: additionalInfo,
                createdAt: createdAt,
                updatedAt: Date()
            )
            assets.append(asset)
        }

        return assets
    }

    static func generateSampleCSV() -> String {
        """
        類別,名稱,數量,建立於,備註
        現金,台新銀行,30000,2025/6/5,包含餐費與交通
        台灣股票,2330.TW,200,2025/6/5,存股用
        台灣股票,0056.TW,1000,2025/6/5,存股用
        美國股票,AMD,120,2025/6/5,
        美國股票,TSLA,500,2025/6/5,長期持有
        房產,新莊街90號3樓,22000000,2025/6/5,
        房貸,新莊街90號3樓,5000000,2025/6/5,
        現金,台北富邦銀行,500000,2025/6/5,
        保險,三商美邦,2000000,2025/6/5,儲蓄險
        保險,國泰人壽,400000,2025/6/5,儲蓄險
        """
    }
}
