import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("帳戶")) {
                    Text("用戶名稱")
                    Text("電子郵件")
                    // ... 你的帳戶資訊
                }

                Section(header: Text("資料管理")) {
                    NavigationLink(destination: InputAssetsView()) {
                        Text("輸入/管理現有財產")
                    }
                }

                Section(header: Text("設定")) {
                    Text("偏好設定")
                    Text("通知")
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Text("重置用戶資料")
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .foregroundColor(.red)
                    }
                }

                Section {
                    Button("登出") {
                        // 執行登出操作
                        print("登出")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("我的")
            .alert("確認重置", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    // 執行重置操作
                    assetManager.resetAllData()
                }
            } message: {
                Text("確定要重置所有用戶資料嗎？此操作無法撤銷。")
            }
        }
    }
}

#Preview {
    MyPageView()
        .environmentObject(AssetManager())
}
