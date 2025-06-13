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
            pieChartContent(geometry: geometry)
        }
    }

    @ViewBuilder
    private func pieChartContent(geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) * 0.38
        let labelRadius = radius * 1.35 //調整文字跟圖餅圖的距離

        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                pieSlice(index: index, item: item, center: center, radius: radius)
                if item.1 / total >= 0.03 {
                    pieLabel(index: index, item: item, center: center, labelRadius: labelRadius)
                }
            }
        }
//        .rotation3DEffect(
//            .degrees(20), // 傾斜角度
//            axis: (x: 1.0, y: 0.0, z: 0.0), // 沿 X 軸旋轉
//            anchor: .center,
//            perspective: 0.3 // 景深效果
//        )
    }

    @ViewBuilder
    private func pieSlice(index: Int, item: (String, Double, Color), center: CGPoint, radius: CGFloat) -> some View {
        let startAngle = Angle(degrees: angles[index].startAngle - 90)
        let endAngle = Angle(degrees: angles[index].endAngle - 90)
        Path { path in
            path.move(to: center)
            path.addArc(center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
        }
        .fill(item.2)

        .fill(LinearGradient(gradient: Gradient(colors: [item.2.opacity(0.8), item.2]), startPoint: .topLeading, endPoint: .bottomTrailing))
        // 為每個扇區添加一個白色邊框，使其視覺上更清晰、有分隔感
        .stroke(Color.white, lineWidth: 2) // 這條是扇區之間的白邊
//        .stroke(Color.white.opacity(0.5), lineWidth: 1) // 淺色邊框
        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 5)
    }

    @ViewBuilder
    private func pieLabel(index: Int, item: (String, Double, Color), center: CGPoint, labelRadius: CGFloat) -> some View {
        let startAngle = Angle(degrees: angles[index].startAngle - 90)
        let endAngle = Angle(degrees: angles[index].endAngle - 90)
        let midAngle = startAngle + (endAngle - startAngle) / 2
//        let labelPosition = CGPoint(
//            x: center.x + labelRadius * cos(midAngle.radians),
//            y: center.y + labelRadius * sin(midAngle.radians)
//        )
// 上述這段，模擬器可以build，實機不行，要改下段方式
        let labelPosition = CGPoint(
            x: center.x + labelRadius * Foundation.cos(midAngle.radians),
            y: center.y + labelRadius * Foundation.sin(midAngle.radians)
        )

        VStack(spacing: 2) {
            Text(item.0)
                .font(.title3)
            Text(formatPercentage(item.1))
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
        .position(labelPosition)
    }
}

#Preview {
    AssetPieChartView(
        data: [
            ("現金", 1000000, .blue),
            ("保險", 500000, .orange),
            ("股票", 2000000, .green),
            ("不動產", 3000000, .purple)
        ],
        total: 6500000
    )
    .frame(height: 300)
    .padding()
}
