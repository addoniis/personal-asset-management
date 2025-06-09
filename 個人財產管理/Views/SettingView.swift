import SwiftUI

struct SettingView: View {
    @EnvironmentObject var assetManager: AssetManager

    // 匯率更新設定
    @AppStorage("autoUpdateRate") private var autoUpdateRate = true
    @AppStorage("rateUpdateInterval") private var rateUpdateInterval = 24.0 // 小時

    var body: some View {
        List {
            Section(header: Text("匯率設定")) {
                Toggle("自動更新匯率", isOn: $autoUpdateRate)

                if autoUpdateRate {
                    Picker("更新頻率", selection: $rateUpdateInterval) {
                        Text("每6小時").tag(6.0)
                        Text("每12小時").tag(12.0)
                        Text("每24小時").tag(24.0)
                    }
                }

                ForEach(Currency.allCases.filter { $0 != .twd }) { currency in
                    NavigationLink {
                        CurrencyEditView(currency: currency)
                    } label: {
                        HStack {
                            Text(currency.displayName)
                            Spacer()
                            Text(String(format: "%.2f", currency.exchangeRate))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                NavigationLink("資產餘額提醒") {
                    BalanceAlertSettingView()
                }

                NavigationLink("定期盤點提醒") {
                    InventoryReminderView()
                }

                NavigationLink("到期日提醒") {
                    ExpiryReminderView()
                }
            }
        }
        .navigationTitle("設定")
    }
}

// 這些是佔位的視圖，之後會實現具體功能
struct CurrencyEditView: View {
    let currency: Currency
    var body: some View {
        Text("匯率設定 - \(currency.displayName)")
    }
}

struct BalanceAlertSettingView: View {
    var body: some View {
        Text("餘額提醒設定")
    }
}

struct InventoryReminderView: View {
    var body: some View {
        Text("盤點提醒設定")
    }
}

struct ExpiryReminderView: View {
    var body: some View {
        Text("到期提醒設定")
    }
}

#Preview {
    NavigationView {
        SettingView()
            .environmentObject(AssetManager.shared)
    }
}
