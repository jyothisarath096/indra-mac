import SwiftUI

struct WelcomeView: View {
    @State private var showSetup   = false
    @State private var showRestore = false

    var body: some View {
        ZStack {
            Color.indraBlack.ignoresSafeArea()
            VStack(spacing: 48) {
                Spacer()
                VStack(spacing: 12) {
                    Text("⚡")
                        .font(.system(size: 64))
                    Text("INDRA")
                        .font(.indraWordmark)
                        .tracking(12)
                        .foregroundColor(.indraText)
                    Text("NODE")
                        .font(.indraLabel)
                        .tracking(8)
                        .foregroundColor(.indraGold)
                }
                Text("Run INDRA. Secure the network. Earn INDRA.")
                    .font(.indraBody)
                    .foregroundColor(.indraMuted)
                VStack(spacing: 12) {
                    INDRAButton(title: "Set Up New Node") { showSetup = true }
                        .frame(width: 320)
                    INDRAButton(
                        title: "Restore from Recovery Phrase",
                        action: { showRestore = true },
                        style: .secondary
                    )
                    .frame(width: 320)
                }
                Spacer()
                Text("Post-quantum settlement network")
                    .font(.indraMonoSmall)
                    .foregroundColor(.indraMuted.opacity(0.5))
            }
            .padding(48)
        }
        .sheet(isPresented: $showSetup) {
            SetupWizardView()
                .frame(width: 680, height: 560)
        }
        .sheet(isPresented: $showRestore) {
            RestoreWalletView()
                .frame(width: 680, height: 540)
        }
    }
}
