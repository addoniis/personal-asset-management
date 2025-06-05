import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAbout = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("個人資訊")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("使用者")
                                .font(.headline)
                            Text("個人財產管理")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("資產設定")) {
                    NavigationLink(destination: Text("資產分類管理")) {
                        Label("資產分類管理", systemImage: "folder")
                    }

                    NavigationLink(destination: Text("匯率設定")) {
                        Label("匯率設定", systemImage: "dollarsign.circle")
                    }
                }

                Section(header: Text("應用設定")) {
                    NavigationLink(destination: Text("通知設定")) {
                        Label("通知設定", systemImage: "bell")
                    }

                    Button(action: {
                        showingAbout = true
                    }) {
                        Label("關於", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("我的")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text("個人財產管理")
                            .font(.title)

                        Text("版本 1.0.0")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                Section(header: Text("開發者資訊")) {
                    Text("開發者：Adonis")
                }
            }
            .navigationTitle("關於")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AssetManager())
}
