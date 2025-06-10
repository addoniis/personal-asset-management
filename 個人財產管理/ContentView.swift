import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            CashView()
                .tabItem {
                    Label("現金", systemImage: "dollarsign.circle")
                }
                .tag(0)

            StockView()
                .tabItem {
                    Label("股票", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            PropertyView()
                .tabItem {
                    Label("不動產", systemImage: "building.2")                }
                .tag(2)

            InsuranceView()
                .tabItem {
                    Label("保險", systemImage: "shield")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
                .tag(4)
        }
        .environmentObject(assetManager)
    }
}

#Preview {
    ContentView()
}
