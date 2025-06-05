import SwiftUI

struct MyPageView: View {
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
                    // ... 你的應用設定
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
        }
    }
}

#Preview {
    MyPageView()
}
