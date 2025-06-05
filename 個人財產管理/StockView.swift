import SwiftUI

struct StockView: View {
    @State private var selectedStockType = 0 // 0: 台股, 1: 美股

    var body: some View {
        NavigationView {
            VStack {
                Picker("選擇市場", selection: $selectedStockType) {
                    Text("台股").tag(0)
                    Text("美股").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedStockType == 0 {
                    TaiwanStockView()
                } else {
                    USStockView()
                }

                Spacer() // 將內容推到頂部
            }
            .navigationTitle("股票")
        }
    }
}

#Preview {
    StockView()
}
