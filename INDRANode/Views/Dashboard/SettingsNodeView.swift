import SwiftUI

struct SettingsNodeView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @EnvironmentObject var walletStore: NodeWalletStore
    @State private var showResetConfirm = false
    @State private var rpcPort = "8545"
    @State private var p2pPort = "30303"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("SETTINGS")
                    .font(.indraTitle).tracking(4).foregroundColor(.indraGold)
                    .padding(.top, 32)

                // Node
                VStack(alignment: .leading, spacing: 12) {
                    INDRASectionLabel(text: "Node Configuration")
                    INDRACard {
                        VStack(alignment: .leading, spacing: 12) {
                            settingRow("Data Directory", nodeManager.dataDirectory)
                            INDRADivider()
                            settingRow("Node Binary", nodeManager.nodeBinaryPath)
                            INDRADivider()
                            HStack {
                                Text("RPC Port").font(.indraBody).foregroundColor(.indraText)
                                Spacer()
                                TextField("8545", text: $rpcPort)
                                    .textFieldStyle(.plain).font(.indraMono)
                                    .foregroundColor(.indraGold)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                            INDRADivider()
                            HStack {
                                Text("P2P Port").font(.indraBody).foregroundColor(.indraText)
                                Spacer()
                                TextField("30303", text: $p2pPort)
                                    .textFieldStyle(.plain).font(.indraMono)
                                    .foregroundColor(.indraGold)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                }

                // Storage
                VStack(alignment: .leading, spacing: 12) {
                    INDRASectionLabel(text: "Storage")
                    INDRACard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Available Disk").font(.indraBody).foregroundColor(.indraText)
                                Spacer()
                                Text(String(format: "%.1f GB", nodeManager.diskAvailableGB))
                                    .font(.indraMono)
                                    .foregroundColor(nodeManager.diskAvailableGB < 5
                                        ? .indraRed : .indraGreen)
                            }
                            INDRADivider()
                            HStack {
                                Text("Prune Window").font(.indraBody).foregroundColor(.indraText)
                                Spacer()
                                Text("50,000 blocks (~300 MB)")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                            }
                            INDRADivider()
                            HStack {
                                Text("Mode").font(.indraBody).foregroundColor(.indraText)
                                Spacer()
                                Text("Pruned (validator default)")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                            }
                        }
                    }
                }

                // About
                VStack(alignment: .leading, spacing: 12) {
                    INDRASectionLabel(text: "About")
                    INDRACard {
                        VStack(alignment: .leading, spacing: 12) {
                            settingRow("Version", "0.1.0-testnet")
                            INDRADivider()
                            settingRow("Network", "indra-testnet-1")
                            INDRADivider()
                            settingRow("Validator Set Phase",
                                       "Phase \(nodeManager.validatorSetPhase)")
                            INDRADivider()
                            settingRow("Active Validators",
                                       "\(nodeManager.activeValidators) / \(nodeManager.maxActiveValidators)")
                        }
                    }
                }

                // Identity
                VStack(alignment: .leading, spacing: 12) {
                    INDRASectionLabel(text: "Validator Identity")
                    INDRACard {
                        VStack(alignment: .leading, spacing: 12) {
                            if let id = walletStore.validatorId {
                                HStack {
                                    Text("Validator ID")
                                        .font(.indraBody).foregroundColor(.indraText)
                                    Spacer()
                                    Text(shortId(id))
                                        .font(.indraMono).foregroundColor(.indraGold)
                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(id, forType: .string)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.indraGoldDim)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Danger zone
                VStack(alignment: .leading, spacing: 12) {
                    INDRASectionLabel(text: "Danger Zone")
                    INDRAButton(title: "Reset Node — Sign Out", action: { showResetConfirm = true }, style: .destructive)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 32)
        }
        .background(Color.indraBlack)
        .confirmationDialog(
            "Reset Node?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset and Sign Out", role: .destructive) {
                nodeManager.stopNode()
                walletStore.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Make sure you have your 24-word recovery phrase saved. Your funds are safe — recover anytime with your phrase.")
        }
    }

    func settingRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.indraBody).foregroundColor(.indraText)
            Spacer()
            Text(value)
                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                .lineLimit(1).truncationMode(.middle)
        }
    }
}
