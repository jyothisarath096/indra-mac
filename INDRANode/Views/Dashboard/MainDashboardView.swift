import SwiftUI

struct MainDashboardView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @EnvironmentObject var walletStore: NodeWalletStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("DASHBOARD")
                    .font(.indraTitle).tracking(4).foregroundColor(.indraGold)
                    .padding(.top, 32)

                // MARK: Status + Network (combined)
                INDRACard {
                    VStack(spacing: 16) {
                        // Status row
                        HStack(spacing: 10) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: statusColor.opacity(0.6), radius: 3)
                            Text(statusTitle)
                                .font(.indraBody).foregroundColor(.indraText)
                            Spacer()
                            if nodeManager.blockHeight > 0 {
                                Text("BLOCK #\(nodeManager.blockHeight)")
                                    .font(.indraMonoSmall).tracking(1)
                                    .foregroundColor(.indraGreen)
                            }
                        }

                        if !statusSubtitle.isEmpty {
                            Text(statusSubtitle)
                                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        INDRADivider()

                        // Stats row
                        HStack(spacing: 0) {
                            miniStat("HEIGHT", "\(nodeManager.blockHeight)")
                            Divider().background(Color.indraBorder)
                            miniStat("EPOCH", "\(nodeManager.currentEpoch)")
                            Divider().background(Color.indraBorder)
                            miniStat("PEERS", "\(nodeManager.connectedPeers)")
                            Divider().background(Color.indraBorder)
                            miniStat("VALIDATORS",
                                     "\(nodeManager.activeValidators)/\(nodeManager.maxActiveValidators)")
                            Divider().background(Color.indraBorder)
                            miniStat("PHASE", "\(nodeManager.validatorSetPhase)")
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        // Peers progress bar (only when waiting)
                        if nodeManager.status.isRunning && nodeManager.blockHeight == 0 {
                            VStack(spacing: 4) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle().fill(Color.indraBorder).frame(height: 3)
                                        Rectangle()
                                            .fill(nodeManager.connectedPeers >= nodeManager.peersNeeded
                                                ? Color.indraGreen : Color.indraGold)
                                            .frame(
                                                width: geo.size.width
                                                    * Double(min(nodeManager.connectedPeers + 1,
                                                                 nodeManager.peersNeeded + 1))
                                                    / Double(nodeManager.peersNeeded + 1),
                                                height: 3
                                            )
                                    }.cornerRadius(1.5)
                                }
                                .frame(height: 3)
                                Text("\(nodeManager.connectedPeers + 1) of \(nodeManager.peersNeeded + 1) validators needed for consensus")
                                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
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
                                    if let name = walletStore.displayName,
                                       !name.isEmpty {
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
                            Text("Your address on the INDRA network.")
                                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                        }
                    }
                }

                // MARK: Disk warning
                if nodeManager.diskAvailableGB > 0 && nodeManager.diskAvailableGB < 5 {
                    INDRACard {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(nodeManager.diskAvailableGB < 0.5
                                    ? .indraRed : .indraGold)
                            Text(nodeManager.diskAvailableGB < 0.5
                                ? "CRITICAL: \(String(format: "%.1f", nodeManager.diskAvailableGB)) GB remaining."
                                : "WARNING: \(String(format: "%.1f", nodeManager.diskAvailableGB)) GB disk remaining.")
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

    // MARK: - Status helpers
    var statusColor: Color {
        guard nodeManager.status.isRunning else { return .indraMuted }
        if nodeManager.blockHeight > 0 { return .indraGreen }
        if nodeManager.connectedPeers >= nodeManager.peersNeeded { return .indraGold }
        return .indraRed
    }

    var statusTitle: String {
        guard nodeManager.status.isRunning else { return "Node Offline" }
        if nodeManager.blockHeight > 0 { return "Producing Blocks" }
        if nodeManager.connectedPeers >= nodeManager.peersNeeded { return "Consensus Forming" }
        return "Waiting for Peers"
    }

    var statusSubtitle: String {
        guard nodeManager.status.isRunning else { return "" }
        if nodeManager.blockHeight > 0 { return "" }
        let needed = nodeManager.peersNeeded - nodeManager.connectedPeers
        if needed > 0 {
            return "Need \(needed) more validator\(needed == 1 ? "" : "s") online · BFT requires >66% of \(nodeManager.activeValidators)"
        }
        return "Validators connected · waiting for first block"
    }

    // MARK: - Stat cells
    func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9)).tracking(1).foregroundColor(.indraMuted)
            Text(value)
                .font(.indraMono).foregroundColor(.indraText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
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
