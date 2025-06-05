import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 首頁
            HomePageView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
            // 現金
            CaseView()
                .tabItem {
                    Label("現金", systemImage: "dollarsign.ring")
                }

            // 股票
            StockView()
                .tabItem {
                    Label("股票", systemImage: "chart.line.uptrend.xyaxis")
                }

            // 房產
            PropertyView()
                .tabItem {
                    Label("房產", systemImage: "house.lodge.fill")
                }

            // 我的
            MyPageView()
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
