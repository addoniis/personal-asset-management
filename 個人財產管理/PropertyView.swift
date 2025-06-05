import SwiftUI

struct PropertyView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("房產")) {
                    Text("XX 市 XX 路 XX 號 (出租)")
                    Text("YY 市 YY 街 YY 號 (自住)")
                    // ... 你的房產列表
                }
                Section(header: Text("房貸")) {
                    Text("貸款銀行：...")
                    Text("貸款金額：...")
                    Text("利率：...")
                    Text("剩餘還款期限：...")
                    // ... 你的房貸詳細資訊
                }
            }
            .navigationTitle("房屋資產")
            
        }
    }
}

#Preview {
    PropertyView()
}
