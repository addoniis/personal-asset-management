import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject var assetManager: AssetManager
    @State private var showingAbout = false
    @State private var showingResetAlert = false
    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""

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

                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Label("重置用戶資料", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("資料管理")) {
                    Button(action: {
                        showingImportPicker = true
                    }) {
                        Label("匯入CSV資料", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        showingExportSheet = true
                    }) {
                        Label("匯出CSV資料", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .alert("確認重置", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    assetManager.resetAllData()
                }
            } message: {
                Text("確定要重置所有用戶資料嗎？此操作無法撤銷。")
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let selectedFile = files.first else { return }

                    do {
                        let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                        assetManager.importAssetsFromCSV(fileContent)
                        importAlertMessage = "匯入成功！"
                        showingImportAlert = true
                    } catch {
                        importAlertMessage = "匯入失敗：\(error.localizedDescription)"
                        showingImportAlert = true
                    }

                case .failure(let error):
                    importAlertMessage = "選擇檔案失敗：\(error.localizedDescription)"
                    showingImportAlert = true
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                let csvData = assetManager.exportAssetsToCSV()
                ShareSheet(activityItems: [csvData])
            }
            .alert(isPresented: $showingImportAlert) {
                Alert(
                    title: Text("匯入結果"),
                    message: Text(importAlertMessage),
                    dismissButton: .default(Text("確定"))
                )
            }
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
        .environmentObject(AssetManager())
}
