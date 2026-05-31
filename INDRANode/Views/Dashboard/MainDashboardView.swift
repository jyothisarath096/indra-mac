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

                // MARK: Consensus Status
                consensusCard

                // MARK: Network Stats
                INDRACard {
                    VStack(spacing: 12) {
                        INDRASectionLabel(text: "Network")
                        HStack(spacing: 0) {
                            statCell("Block Height", "\(nodeManager.blockHeight)")
                            Divider().background(Color.indraBorder)
                            statCell("Epoch", "\(nodeManager.currentEpoch)")
                            Divider().background(Color.indraBorder)
                            statCell("Peers Online", "\(nodeManager.connectedPeers)")
                            Divider().background(Color.indraBorder)
                            statCell("Phase", "\(nodeManager.validatorSetPhase)")
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // MARK: Validator Set
                INDRACard {
                    VStack(alignment: .leading, spacing: 12) {
                        INDRASectionLabel(text: "Validator Set")
                        HStack(spacing: 0) {
                            statCell("In Consensus Set",
                                     "\(nodeManager.activeValidators)",
                                     unit: "of \(nodeManager.maxActiveValidators) slots")
                            Divider().background(Color.indraBorder)
                            statCell("Peers Connected",
                                     "\(nodeManager.connectedPeers)",
                                     unit: "online now")
                            Divider().background(Color.indraBorder)
                            statCell("Slots Available",
                                     "\(nodeManager.maxActiveValidators - nodeManager.activeValidators)",
                                     unit: "open")
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        // Consensus set progress bar
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Consensus Set Capacity")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                                Spacer()
                                Text("\(nodeManager.activeValidators) registered · \(nodeManager.connectedPeers) online")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.indraBorder).frame(height: 4)
                                    // Registered validators (gold)
                                    Rectangle()
                                        .fill(Color.indraGold)
                                        .frame(
                                            width: nodeManager.maxActiveValidators > 0
                                                ? geo.size.width * Double(nodeManager.activeValidators) / Double(nodeManager.maxActiveValidators)
                                                : 0,
                                            height: 4
                                        )
                                    // Online peers (green overlay)
                                    Rectangle()
                                        .fill(Color.indraGreen)
                                        .frame(
                                            width: nodeManager.maxActiveValidators > 0
                                                ? geo.size.width * Double(nodeManager.connectedPeers + 1) / Double(nodeManager.maxActiveValidators)
                                                : 0,
                                            height: 4
                                        )
                                }
                                .cornerRadius(2)
                            }
                            .frame(height: 4)
                            HStack {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.indraGreen).frame(width: 6, height: 6)
                                    Text("Online").font(.indraMonoSmall).foregroundColor(.indraMuted)
                                }
                                HStack(spacing: 4) {
                                    Circle().fill(Color.indraGold).frame(width: 6, height: 6)
                                    Text("In set").font(.indraMonoSmall).foregroundColor(.indraMuted)
                                }
                                HStack(spacing: 4) {
                                    Circle().fill(Color.indraBorder).frame(width: 6, height: 6)
                                    Text("Open slots").font(.indraMonoSmall).foregroundColor(.indraMuted)
                                }
                            }
                        }
                    }
                }

                // MARK: Wallet
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

                // MARK: Validator Identity
                if let id = walletStore.validatorId {
                    INDRACard {
                        VStack(alignment: .leading, spacing: 8) {
                            INDRASectionLabel(text: "Validator Identity")
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let name = walletStore.displayName {
                                        Text(name)
                                            .font(.indraBody).foregroundColor(.indraText)
                                    }
                                    Text(id)
                                        .font(.indraMono).foregroundColor(.indraGold)
                                        .lineLimit(1).truncationMode(.middle)
                                }
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

                // MARK: Disk warning
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

    // MARK: Consensus Status Card
    var consensusCard: some View {
        INDRACard {
            VStack(alignment: .leading, spacing: 12) {
                INDRASectionLabel(text: "Consensus Status")

                HStack(spacing: 12) {
                    // Status indicator
                    Circle()
                        .fill(consensusColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: consensusColor.opacity(0.5), radius: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(consensusTitle)
                            .font(.indraBody).foregroundColor(.indraText)
                        Text(consensusSubtitle)
                            .font(.indraMonoSmall).foregroundColor(.indraMuted)
                    }

                    Spacer()

                    if nodeManager.blockHeight > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("LAST BLOCK")
                                .font(.indraMonoSmall).tracking(1).foregroundColor(.indraMuted)
                            Text("#\(nodeManager.blockHeight)")
                                .font(.indraTitle).foregroundColor(.indraGreen)
                        }
                    }
                }

                // Peers needed bar
                if nodeManager.connectedPeers < nodeManager.peersNeeded {
                    let needed = nodeManager.peersNeeded
                    let have = nodeManager.connectedPeers + 1 // include self
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Validators online")
                                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                            Spacer()
                            Text("\(have) of \(needed + 1) needed for consensus")
                                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.indraBorder).frame(height: 6)
                                Rectangle()
                                    .fill(have >= needed + 1 ? Color.indraGreen : Color.indraGold)
                                    .frame(
                                        width: geo.size.width * Double(min(have, needed + 1)) / Double(needed + 1),
                                        height: 6
                                    )
                            }
                            .cornerRadius(3)
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    var consensusColor: Color {
        if nodeManager.blockHeight > 0 { return .indraGreen }
        if nodeManager.connectedPeers >= nodeManager.peersNeeded { return .indraGold }
        return .indraRed
    }

    var consensusTitle: String {
        if !nodeManager.status.isRunning { return "Node Offline" }
        if nodeManager.blockHeight > 0 { return "Producing Blocks" }
        if nodeManager.connectedPeers >= nodeManager.peersNeeded { return "Consensus Forming" }
        return "Waiting for Peers"
    }

    var consensusSubtitle: String {
        if !nodeManager.status.isRunning {
            return "Start the node to participate in consensus"
        }
        if nodeManager.blockHeight > 0 {
            return "Chain is active · Block #\(nodeManager.blockHeight)"
        }
        let needed = nodeManager.peersNeeded - nodeManager.connectedPeers
        if needed > 0 {
            return "Need \(needed) more validator\(needed == 1 ? "" : "s") online (BFT requires >66% of \(nodeManager.activeValidators))"
        }
        return "Validators connected · waiting for first block"
    }

    func statCell(_ label: String, _ value: String, unit: String = "") -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.indraMonoSmall).tracking(1).foregroundColor(.indraMuted)
                .multilineTextAlignment(.center)
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
