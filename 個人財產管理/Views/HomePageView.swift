import SwiftUI

struct HomePageView: View {
    @StateObject private var assetManager = AssetManager.shared
    @State private var showingAddAsset = false
    @State private var showingAnalytics = false
    @State private var selectedTimeRange = 1 // 1: 月, 3: 季, 12: 年

    private var timeRanges = [(1, "月"), (3, "季"), (12, "年")]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 總資產卡片
                    AssetCardView(
                        title: "總資產",
                        amount: assetManager.totalAssets,
                        trend: assetManager.monthlyGrowthRate,
                        color: .blue
                    )
                    .onTapGesture {
                        showingAnalytics = true
                    }

                    // 時間範圍選擇器
                    Picker("時間範圍", selection: $selectedTimeRange) {
                        ForEach(timeRanges, id: \.0) { range in
                            Text(range.1).tag(range.0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 資產趨勢圖
                    TrendChart(months: selectedTimeRange)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)

                    // 資產分類列表
                    AssetCategoryListView(
                        categories: AssetCategory.allCases.map { category in
                            (
                                category.rawValue,
                                assetManager.assetsByCategory[category] ?? 0,
                                category.color
                            )
                        },
                        total: assetManager.totalAssets
                    )
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("資產概覽")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAsset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAsset) {
                NavigationView {
                    AssetInputForm(
                        assetName: .constant(""),
                        amount: .constant(""),
                        category: .constant(.cash),
                        date: .constant(Date()),
                        notes: .constant("")
                    ) {
                        // Handle asset addition
                    }
                    .navigationTitle("新增資產")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") {
                                showingAddAsset = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                NavigationView {
                    AssetAnalyticsView()
                        .navigationTitle("資產分析")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("關閉") {
                                    showingAnalytics = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// 為 AssetCategory 添加顏色屬性
extension AssetCategory {
    var color: Color {
        switch self {
        case .cash:
            return .blue
        case .stock:
            return .green
        case .fund:
            return .orange
        case .property:
            return .purple
        case .insurance:
            return .red
        case .mortgage:
            return .brown
        case .other:
            return .gray
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
            .environmentObject(AssetManager.shared)
    }
}
