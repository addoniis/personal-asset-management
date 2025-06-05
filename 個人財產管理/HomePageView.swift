import SwiftUI

struct HomePageView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("資產總覽")
                    .font(.headline)
                    .padding()

                // 在這裡顯示動產和不動產的總價值

                Divider()

                Text("快速入口")
                    .font(.headline)
                    .padding()

                HStack {
                    NavigationLink(destination: CaseView()) {
                        QuickActionButton(title: "現金", icon: "dollarsign.ring")
                    }
                    NavigationLink(destination: StockView()) {
                        QuickActionButton(title: "股票", icon: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink(destination: PropertyView()) {
                        QuickActionButton(title: "房產", icon: "house.lodge.fill")
                    }
                    // 可以根據你的需求添加更多快速入口
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("首頁")
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .padding(.bottom, 5)
            Text(title)
                .font(.subheadline)
        }
        .frame(width: 80, height: 80)
        .background(Color.gray.opacity(0.2)) // 淺灰色背景
        .cornerRadius(10)
    }
}

#Preview {
    HomePageView()
}
