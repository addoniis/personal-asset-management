import SwiftUI

struct USStockView: View {
    var body: some View {
        List {
            Section(header: Text("美股")) {
                Text("Apple (AAPL) - 10 股")
                Text("Tesla (TSLA) - 5 股")
                // ... 你的美股列表
            }
        }
        .navigationTitle("美股")
    }
}

#Preview {
    USStockView()
}
