import SwiftUI
import Charts

struct AssetTrendChartView: View {
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    let data: [DataPoint]
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.blue.gradient)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.blue.opacity(0.1))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month())
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .currency(code: "USD"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let data = Array((0..<6).map { i in
        AssetTrendChartView.DataPoint(
            date: calendar.date(byAdding: .month, value: -i, to: today)!,
            value: Double.random(in: 90000...110000)
        )
    }.reversed())

    return AssetTrendChartView(data: data, title: "資產趨勢")
        .padding()
        .background(Color(.systemGray6))
}
