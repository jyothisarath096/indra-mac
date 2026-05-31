import SwiftUI

struct RootView: View {
    @EnvironmentObject var walletStore: NodeWalletStore

    var body: some View {
        Group {
            if walletStore.isOnboarded {
                DashboardView()
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
