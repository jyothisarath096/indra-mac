import SwiftUI

@main
struct INDRANodeApp: App {
    @StateObject private var nodeManager = NodeManager.shared
    @StateObject private var walletStore = NodeWalletStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(nodeManager)
                .environmentObject(walletStore)
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
