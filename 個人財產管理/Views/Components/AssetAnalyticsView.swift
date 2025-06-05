import SwiftUI
import Charts

struct AssetAnalyticsView: View {
    @StateObject private var assetManager = AssetManager.shared
    @State private var selectedTimeRange = 12 // 預設顯示一年
    @State private var selectedChart = ChartType.trend

    enum ChartType: String, CaseIterable {
        case trend = "趨勢"
        case distribution = "分佈"
        case growth = "增長"
        case comparison = "比較"
    }

    var body: some View {
        VStack(spacing: 20) {
            // 圖表類型選擇器
            Picker("圖表類型", selection: $selectedChart) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // 時間範圍選擇器（僅在趨勢圖和增長圖中顯示）
            if selectedChart == .trend || selectedChart == .growth {
                TimeRangePicker(selection: $selectedTimeRange)
            }

            // 根據選擇顯示不同的圖表
            switch selectedChart {
            case .trend:
                TrendChart(months: selectedTimeRange)
            case .distribution:
                DistributionChart()
            case .growth:
                GrowthChart(months: selectedTimeRange)
            case .comparison:
                ComparisonChart()
            }
        }
        .padding()
    }
}

// 時間範圍選擇器
struct TimeRangePicker: View {
    @Binding var selection: Int
    private let ranges = [(1, "1月"), (3, "3月"), (6, "半年"), (12, "1年"), (24, "2年")]

    var body: some View {
        Picker("時間範圍", selection: $selection) {
            ForEach(ranges, id: \.0) { range in
                Text(range.1).tag(range.0)
            }
        }
        .pickerStyle(.segmented)
    }
}

// 趨勢圖
struct TrendChart: View {
    let months: Int
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("資產趨勢")
                .font(.headline)

            Chart {
                ForEach(assetManager.getAssetHistory(months: months)) { history in
                    LineMark(
                        x: .value("日期", history.date),
                        y: .value("總額", history.totalValue)
                    )
                    .foregroundStyle(Color.blue.gradient)

                    AreaMark(
                        x: .value("日期", history.date),
                        y: .value("總額", history.totalValue)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1))
                }
            }
            .frame(height: 200)
        }
    }
}

// 分佈圖
struct DistributionChart: View {
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("資產分佈")
                .font(.headline)

            if #available(iOS 17.0, *) {
                Chart(Array(assetManager.assetsByCategory), id: \.key) { category, value in
                    SectorMark(
                        angle: .value("金額", value),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(category.displayColor)
                    .annotation(position: .overlay) {
                        Text("\(Int(value/assetManager.totalAssets*100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 200)
            } else {
                // iOS 17.0 以前的替代方案
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(assetManager.assetsByCategory.enumerated()), id: \.element.key) { index, item in
                            let (category, value) = item
                            let percentage = value / assetManager.totalAssets
                            let startAngle = getStartAngle(for: index, in: assetManager.assetsByCategory)
                            let endAngle = startAngle + .degrees(360 * percentage)

                            Path { path in
                                path.move(to: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                                path.addArc(center: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2),
                                          radius: min(geometry.size.width, geometry.size.height)/2,
                                          startAngle: startAngle,
                                          endAngle: endAngle,
                                          clockwise: false)
                            }
                            .fill(category.displayColor)

                            if percentage > 0.05 {
                                let midAngle = startAngle + .degrees(360 * percentage/2)
                                let radius = min(geometry.size.width, geometry.size.height)/3
                                let x = geometry.size.width/2 + radius * cos(midAngle.radians)
                                let y = geometry.size.height/2 + radius * sin(midAngle.radians)

                                Text("\(Int(percentage*100))%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .position(x: x, y: y)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // 圖例
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(assetManager.assetsByCategory), id: \.key) { category, value in
                    HStack {
                        Circle()
                            .fill(category.displayColor)
                            .frame(width: 10, height: 10)
                        Text(category.displayName)
                        Spacer()
                        Text(formatCurrency(value))
                    }
                }
            }
            .font(.caption)
            .padding(.top)
        }
    }

    private func getStartAngle(for index: Int, in categories: [AssetCategory: Double]) -> Angle {
        var totalPercentage: Double = 0
        for (i, item) in categories.enumerated() {
            if i < index {
                totalPercentage += item.value / assetManager.totalAssets
            }
        }
        return .degrees(360 * totalPercentage - 90)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// 增長圖
struct GrowthChart: View {
    let months: Int
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("資產增長")
                .font(.headline)

            Chart {
                ForEach(assetManager.getGrowthHistory(months: months), id: \.date) { history in
                    BarMark(
                        x: .value("日期", history.date),
                        y: .value("增長", history.growthRate)
                    )
                    .foregroundStyle(history.growthRate >= 0 ? Color.green : Color.red)
                }
            }
            .frame(height: 200)
        }
    }
}

// 比較圖
struct ComparisonChart: View {
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("資產類別比較")
                .font(.headline)

            Chart {
                ForEach(Array(assetManager.assetsByCategory), id: \.key) { category, value in
                    BarMark(
                        x: .value("類別", category.displayName),
                        y: .value("金額", value)
                    )
                    .foregroundStyle(category.displayColor)
                }
            }
            .frame(height: 200)
        }
    }
}

#Preview {
    AssetAnalyticsView()
}
