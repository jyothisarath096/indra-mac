import SwiftUI

struct MainDashboardView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @EnvironmentObject var walletStore: NodeWalletStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DASHBOARD")
                    .font(.indraTitle).tracking(4).foregroundColor(.indraGold)
                    .padding(.top, 32)

                // Chain stats
                INDRACard {
                    VStack(spacing: 12) {
                        INDRASectionLabel(text: "Network")
                        HStack(spacing: 0) {
                            statCell("Block Height", "\(nodeManager.blockHeight)")
                            Divider().background(Color.indraBorder)
                            statCell("Epoch", "\(nodeManager.currentEpoch)")
                            Divider().background(Color.indraBorder)
                            statCell("Peers", "\(nodeManager.connectedPeers)")
                            Divider().background(Color.indraBorder)
                            statCell("Validators",
                                     "\(nodeManager.activeValidators)/\(nodeManager.maxActiveValidators)")
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Wallet
                INDRACard {
                    VStack(spacing: 12) {
                        INDRASectionLabel(text: "Wallet")
                        HStack(spacing: 0) {
                            statCell("Balance",
                                     formatINDRA(walletStore.balanceSpark),
                                     unit: "INDRA")
                            Divider().background(Color.indraBorder)
                            statCell("Today",
                                     "+" + formatINDRA(walletStore.todayRewardsSpark),
                                     unit: "INDRA")
                            Divider().background(Color.indraBorder)
                            statCell("Total Earned",
                                     formatINDRA(walletStore.rewardsEarnedSpark),
                                     unit: "INDRA")
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Validator ID
                if let id = walletStore.validatorId {
                    INDRACard {
                        VStack(alignment: .leading, spacing: 8) {
                            INDRASectionLabel(text: "Validator Identity")
                            HStack {
                                Text(id)
                                    .font(.indraMono).foregroundColor(.indraGold)
                                    .lineLimit(1).truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(id, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.indraGoldDim)
                                }
                                .buttonStyle(.plain)
                            }
                            Text("Your address on the INDRA network. Share it to receive INDRA or delegation.")
                                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                        }
                    }
                }

                // Validator set phase
                INDRACard {
                    VStack(alignment: .leading, spacing: 10) {
                        INDRASectionLabel(text: "Validator Set")
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Phase \(nodeManager.validatorSetPhase)")
                                    .font(.indraBody).foregroundColor(.indraText)
                                Text("\(nodeManager.activeValidators) active · \(nodeManager.maxActiveValidators) max slots")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                            }
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.indraBorder).frame(height: 4)
                                    Rectangle()
                                        .fill(Color.indraGold)
                                        .frame(
                                            width: nodeManager.maxActiveValidators > 0
                                                ? geo.size.width
                                                    * Double(nodeManager.activeValidators)
                                                    / Double(nodeManager.maxActiveValidators)
                                                : 0,
                                            height: 4
                                        )
                                }
                                .cornerRadius(2)
                            }
                            .frame(width: 140, height: 4)
                        }
                    }
                }

                // Disk warning
                if nodeManager.diskAvailableGB > 0 && nodeManager.diskAvailableGB < 5 {
                    INDRACard {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(nodeManager.diskAvailableGB < 0.5
                                    ? .indraRed : .indraGold)
                            Text(nodeManager.diskAvailableGB < 0.5
                                ? "CRITICAL: \(String(format: "%.1f", nodeManager.diskAvailableGB)) GB remaining. Free space immediately."
                                : "WARNING: \(String(format: "%.1f", nodeManager.diskAvailableGB)) GB disk space remaining.")
                                .font(.indraBody)
                                .foregroundColor(nodeManager.diskAvailableGB < 0.5
                                    ? .indraRed : .indraGold)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 32)
        }
        .background(Color.indraBlack)
    }

    func statCell(_ label: String, _ value: String, unit: String = "") -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.indraMonoSmall).tracking(1).foregroundColor(.indraMuted)
            Text(value)
                .font(.indraTitle).foregroundColor(.indraText)
            if !unit.isEmpty {
                Text(unit).font(.indraMonoSmall).foregroundColor(.indraGold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
