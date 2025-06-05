import SwiftUI

struct TaiwanStockView: View {
    var body: some View {
        List {
            Section(header: Text("台股")) {
                Text("台積電 (2330) - 100 股")
                Text("中華電信 (2412) - 50 股")
                // ... 你的台股列表
            }
        }
        .navigationTitle("台股")
    }
}

#Preview {
    TaiwanStockView()
}
