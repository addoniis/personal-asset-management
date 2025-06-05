import SwiftUI

struct ContentView: View {
    @StateObject private var assetManager = AssetManager()
    @State private var selectedTab = 0

    private var totalAssets: Double {
        assetManager.totalAssets
    }

    var body: some View {
        VStack(spacing: 0) {
            // 總資產顯示
            VStack {
                Text("總資產")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("$\(Int(totalAssets))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))

            // TabView
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
        }
        .environmentObject(assetManager)
    }
}

#Preview {
    ContentView()
}
