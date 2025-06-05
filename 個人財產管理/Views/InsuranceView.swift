import SwiftUI

struct InsuranceView: View {
    @EnvironmentObject var assetManager: AssetManager

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("保險資產總覽")) {
                    HStack {
                        Text("保險總價值")
                        Spacer()
                        Text("\(Int(0))")
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("人壽保險")) {
                    Text("尚無人壽保險資料")
                        .foregroundColor(.gray)
                }

                Section(header: Text("健康保險")) {
                    Text("尚無健康保險資料")
                        .foregroundColor(.gray)
                }

                Section(header: Text("意外保險")) {
                    Text("尚無意外保險資料")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("保險資產")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add insurance
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    InsuranceView()
        .environmentObject(AssetManager())
}
