import SwiftUI

struct CaseView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("現金")
                    .font(.headline)
                    .padding()

                Text("現金銀行：...")
                Text("現金金額：...")
                Spacer()
            }
            .navigationTitle("現金資產")
        }
    }
}

#Preview {
    CaseView()
}
