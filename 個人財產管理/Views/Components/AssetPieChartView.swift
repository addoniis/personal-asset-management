import SwiftUI

struct AssetPieChartView: View {
    let data: [(String, Double, Color)]
    let total: Double

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private var angles: [(startAngle: Double, endAngle: Double)] {
        var startAngle = 0.0
        return data.map { item in
            let angle = 360.0 * (item.1 / total)
            let result = (startAngle, startAngle + angle)
            startAngle += angle
            return result
        }
    }

    private func formatPercentage(_ value: Double) -> String {
        return "\(numberFormatter.string(from: NSNumber(value: (value / total) * 100)) ?? "0")%"
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) * 0.38 //調整圓餅圖的大小
            let labelRadius = radius * 1.2  //調整圓餅圖旁的文字距離

            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let startAngle = Angle(degrees: angles[index].startAngle - 90)
                    let endAngle = Angle(degrees: angles[index].endAngle - 90)
                    let midAngle = startAngle + (endAngle - startAngle) / 2

                    // 扇形
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center,
                                  radius: radius,
                                  startAngle: startAngle,
                                  endAngle: endAngle,
                                  clockwise: false)
                    }
                    .fill(item.2)

                    // 只顯示文字標籤
                    if item.1 / total >= 0.03 { // 只顯示佔比大於3%的標籤
                        let labelPosition = CGPoint(
                            x: center.x + labelRadius * cos(midAngle.radians),
                            y: center.y + labelRadius * sin(midAngle.radians)
                        )

                        VStack(spacing: 2) {
                            Text(item.0)
                                .font(.caption)
                            Text(formatPercentage(item.1))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .position(labelPosition)
                    }
                }
            }
        }
    }
}

#Preview {
    AssetPieChartView(
        data: [
            ("現金", 1000000, .blue),
            ("股票", 2000000, .green),
            ("基金", 500000, .orange),
            ("房地產", 3000000, .purple)
        ],
        total: 6500000
    )
    .frame(height: 300)
    .padding()
}
