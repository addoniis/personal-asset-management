import SwiftUI

struct AssetPieChartView: View {
    let data: [(String, Double, Color)]
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2.2

            ZStack {
                // 圓餅圖
                ForEach(data.indices, id: \.self) { index in
                    if data[index].1 > 0 {
                        PieSlice(
                            startAngle: startAngle(at: index),
                            endAngle: endAngle(at: index)
                        )
                        .fill(data[index].2)
                    }
                }

                // 標籤和指示線
                ForEach(data.indices, id: \.self) { index in
                    if data[index].1 > 0 {
                        let midAngle = (startAngle(at: index).degrees + endAngle(at: index).degrees) / 2
                        let radianAngle = midAngle * .pi / 180

                        let innerPoint = CGPoint(
                            x: center.x + (radius * 0.7) * cos(radianAngle),
                            y: center.y + (radius * 0.7) * sin(radianAngle)
                        )

                        let outerPoint = CGPoint(
                            x: center.x + (radius * 1.2) * cos(radianAngle),
                            y: center.y + (radius * 1.2) * sin(radianAngle)
                        )

                        let textPoint = CGPoint(
                            x: center.x + (radius * 1.4) * cos(radianAngle),
                            y: center.y + (radius * 1.4) * sin(radianAngle)
                        )

                        Path { path in
                            path.move(to: innerPoint)
                            path.addLine(to: outerPoint)
                        }
                        .stroke(data[index].2, lineWidth: 1)

                        let percentage = String(format: "%.1f%%", (data[index].1 / total) * 100)
                        Text("\(data[index].0)\n\(percentage)")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .position(x: textPoint.x, y: textPoint.y)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func startAngle(at index: Int) -> Angle {
        let sumBeforeIndex = data[..<index].reduce(0) { $0 + $1.1 }
        return .degrees(-90 + (sumBeforeIndex / total) * 360)
    }

    private func endAngle(at index: Int) -> Angle {
        let sumThroughIndex = data[...index].reduce(0) { $0 + $1.1 }
        return .degrees(-90 + (sumThroughIndex / total) * 360)
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

#Preview {
    let sampleData: [(String, Double, Color)] = [
        ("現金", 10000, .blue),
        ("股票", 20000, .green),
        ("基金", 15000, .orange),
        ("不動產", 50000, .purple),
        ("保險", 5000, .red),
        ("其他", 3000, .gray)
    ]

    return AssetPieChartView(
        data: sampleData,
        total: sampleData.reduce(0) { $0 + $1.1 }
    )
    .padding(40)
    .background(Color(.systemBackground))
}
