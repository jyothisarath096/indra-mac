import SwiftUI

struct ValidatorInfo: Identifiable {
    let id: String
    let name: String
    let stakeSpark: UInt64
    let isOnline: Bool
    let commissionBps: Int

    var stakeINDRA: Double { Double(stakeSpark) / 100_000_000.0 }
    var commissionPercent: Double { Double(commissionBps) / 100.0 }
    var shortId: String { String(id.prefix(8)) + "..." + String(id.suffix(6)) }
}

struct ValidatorsView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @Environment(\.dismiss) var dismiss
    @State private var validators: [ValidatorInfo] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.indraBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("VALIDATORS")
                        .font(.indraTitle).tracking(4).foregroundColor(.indraGold)
                    Spacer()
                    Text("\(validators.count) of \(nodeManager.maxActiveValidators) slots")
                        .font(.indraMonoSmall).foregroundColor(.indraMuted)
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.indraMuted)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.vertical, 20)
                .background(Color.indraCard)

                Divider().background(Color.indraBorder)

                // Column headers
                HStack {
                    Text("VALIDATOR").font(.indraMonoSmall).tracking(2)
                        .foregroundColor(.indraMuted).frame(maxWidth: .infinity, alignment: .leading)
                    Text("STAKE").font(.indraMonoSmall).tracking(2)
                        .foregroundColor(.indraMuted).frame(width: 120, alignment: .trailing)
                    Text("STATUS").font(.indraMonoSmall).tracking(2)
                        .foregroundColor(.indraMuted).frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Color.indraBlack)

                Divider().background(Color.indraBorder)

                if isLoading {
                    Spacer()
                    ProgressView().tint(.indraGold)
                    Spacer()
                } else if validators.isEmpty {
                    Spacer()
                    Text("No validator data available")
                        .font(.indraBody).foregroundColor(.indraMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(validators.enumerated()), id: \.element.id) { index, v in
                                validatorRow(v, rank: index + 1)
                                Divider().background(Color.indraBorder)
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadValidators() }
    }

    func validatorRow(_ v: ValidatorInfo, rank: Int) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                .frame(width: 24, alignment: .leading)

            // Name + ID
            VStack(alignment: .leading, spacing: 2) {
                Text(v.name)
                    .font(.indraBody).foregroundColor(.indraText)
                Text(v.shortId)
                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Stake
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatINDRA(v.stakeSpark))
                    .font(.indraMono).foregroundColor(.indraText)
                Text("INDRA")
                    .font(.indraMonoSmall).foregroundColor(.indraGold)
            }
            .frame(width: 120, alignment: .trailing)

            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(v.isOnline ? Color.indraGreen : Color.indraMuted)
                    .frame(width: 6, height: 6)
                Text(v.isOnline ? "Online" : "Offline")
                    .font(.indraMonoSmall)
                    .foregroundColor(v.isOnline ? .indraGreen : .indraMuted)
            }
            .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(Color.indraBlack)
    }

    func loadValidators() {
        guard let url = URL(string: "http://127.0.0.1:8545") else {
            isLoading = false; return
        }

        let body = #"{"jsonrpc":"2.0","method":"indra_getValidatorSet","params":[],"id":1}"#
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body.data(using: .utf8)
        req.timeoutInterval = 4

        URLSession.shared.dataTask(with: req) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let result = json["result"] as? [String: Any],
                      let list = result["validators"] as? [[String: Any]] else {
                    // Fallback: show genesis validators from logs
                    self.validators = self.genesisValidators()
                    return
                }

                self.validators = list.compactMap { v -> ValidatorInfo? in
                    guard let id = v["validator_id"] as? String else { return nil }
                    let name = v["name"] as? String ?? shortId(id)
                    let stake = v["stake"] as? UInt64 ?? 0
                    let online = v["online"] as? Bool ?? false
                    let commission = v["commission_bps"] as? Int ?? 0
                    return ValidatorInfo(
                        id: id, name: name, stakeSpark: stake,
                        isOnline: online, commissionBps: commission
                    )
                }
                // Sort by stake descending
                .sorted { $0.stakeSpark > $1.stakeSpark }

                if self.validators.isEmpty {
                    self.validators = self.genesisValidators()
                }
            }
        }.resume()
    }

    // Fallback: show genesis validators when RPC doesn't return them
    func genesisValidators() -> [ValidatorInfo] {
        // Load from genesis.toml if available
        // For now hardcode genesis validators
        // "online" = node is running AND it's our validator ID
        let myId = UserDefaults.standard.string(forKey: "indra.node.validator_id") ?? ""
        let genesisEntries: [(String, String)] = [
            ("9d522a057220b851ddf13fa13d16c57e836809a4410669679e797a45bfad57d2", "buddhi"),
            ("627f00aea2981c4a1b30d613affdec3a94542cbe1f8ffc7f7d28f71c50cbb9ec", "siddhi"),
            ("22ca276a52e9877881abcaf32e9a25ad7d1d5c4795a6bdb5c993688edc088ecc", "kushal mini"),
            ("0453b5bd91ada04fc51df3e0380e6e2528851ca713d4430f08ce15de3b1b5db2", "kushal mac"),
        ]
        return genesisEntries.map { (id, name) in
            ValidatorInfo(
                id: id, name: name,
                stakeSpark: 100_000_000_000,
                isOnline: nodeManager.status.isRunning && id == myId,
                commissionBps: 1000
            )
        }
    }
}
