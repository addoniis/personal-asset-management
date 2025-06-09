import SwiftUI

struct AssetCategoryListView: View {
    let categories: [(String, Double, Color)]
    let total: Double

    var body: some View {
        VStack(spacing: 16) {
            ForEach(categories, id: \.0) { category in
                HStack {
                    Circle()
                        .fill(category.2)
                        .frame(width: 12, height: 12)

                    Text(category.0)
                        .foregroundColor(.primary)

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("NT$\(String(format: "%.0f", category.1))")
                            .fontWeight(.medium)

                        Text("\(String(format: "%.1f", (category.1/total)*100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    AssetCategoryListView(
        categories: [
            ("現金", 50000, .blue),
            ("股票", 30000, .green),
            ("基金", 20000, .orange)
        ],
        total: 100000
    )
    .padding()
    .background(Color(.systemGray6))
}
