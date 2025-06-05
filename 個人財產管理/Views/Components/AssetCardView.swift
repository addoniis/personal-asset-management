import SwiftUI

struct AssetCardView: View {
    let title: String
    let amount: Double
    let trend: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(alignment: .bottom) {
                Text("$\(String(format: "%.2f", amount))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(String(format: "%.1f", abs(trend)))%")
                }
                .foregroundColor(trend >= 0 ? .green : .red)
                .font(.subheadline)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    AssetCardView(
        title: "總資產",
        amount: 150000,
        trend: 2.5,
        color: .blue
    )
}
