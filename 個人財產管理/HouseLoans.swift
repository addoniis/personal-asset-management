import SwiftUI

struct HouseLoansView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("房貸資訊")
                    .font(.headline)
                    .padding()

                Text("貸款銀行：...")
                Text("貸款金額：...")
                Text("利率：...")
                Text("剩餘還款期限：...")
                // ... 你的房貸詳細資訊

                Spacer()
            }
            .navigationTitle("房貸")
        }
    }
}

#Preview {
    HouseLoansView()
}
