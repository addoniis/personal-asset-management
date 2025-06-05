import SwiftUI

struct ContentView: View {
    @StateObject private var assetManager = AssetManager.shared

    var body: some View {
        TabView {
            // 首頁
            HomePageView()
                .environmentObject(assetManager)
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
            // 現金
            CaseView()
                .environmentObject(assetManager)
                .tabItem {
                    Label("現金", systemImage: "dollarsign.ring")
                }

            // 股票
            StockView()
                .environmentObject(assetManager)
                .tabItem {
                    Label("股票", systemImage: "chart.line.uptrend.xyaxis")
                }

            // 房產
            PropertyView()
                .environmentObject(assetManager)
                .tabItem {
                    Label("房產", systemImage: "house.lodge.fill")
                }

            // 我的
            MyPageView()
                .environmentObject(assetManager)
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle.fill")
                }
        }
        .preferredColorScheme(.dark)
        .accentColor(Color(red: 255/255, green: 165/255, blue: 0/255))
    }
}

#Preview {
    ContentView()
}
