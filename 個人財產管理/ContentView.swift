import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            CaseView()
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
                    Label("房產", systemImage: "house")
                }
                .tag(2)

            InsuranceView()
                .tabItem {
                    Label("保險", systemImage: "heart.text.square")
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
