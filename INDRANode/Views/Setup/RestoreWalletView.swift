import SwiftUI

struct RestoreWalletView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletStore: NodeWalletStore
    @EnvironmentObject var nodeManager: NodeManager

    @State private var words = Array(repeating: "", count: 24)
    @State private var errorMessage: String?
    @State private var isValidating = false

    private var isComplete: Bool {
        words.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private var phrase: String {
        words.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
             .joined(separator: " ")
    }

    var body: some View {
        ZStack {
            Color.indraBlack.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RESTORE FROM RECOVERY PHRASE")
                        .font(.indraTitle).foregroundColor(.indraGold)
                    Text("Enter your 24-word recovery phrase to restore your validator identity and wallet.")
                        .font(.indraBody).foregroundColor(.indraMuted)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                    spacing: 6
                ) {
                    ForEach(0..<24, id: \.self) { i in
                        VStack(spacing: 2) {
                            Text("\(i+1)")
                                .font(.system(size: 9)).foregroundColor(.indraMuted)
                            TextField("", text: $words[i])
                                .textFieldStyle(.plain)
                                .font(.indraMonoSmall)
                                .foregroundColor(.indraText)
                                .multilineTextAlignment(.center)
                                .autocorrectionDisabled()
                                .padding(6)
                                .background(Color.indraCard)
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.indraBorder, lineWidth: 0.5))
                        }
                    }
                }

                if let err = errorMessage {
                    Text(err).font(.indraMonoSmall).foregroundColor(.indraRed)
                }

                HStack(spacing: 12) {
                    INDRAButton(title: "Cancel", action: { dismiss() }, style: .secondary)
                    INDRAButton(
                        title: isValidating ? "Restoring..." : "Restore Wallet",
                        action: { restoreWallet() },
                        disabled: !isComplete || isValidating
                    )
                }
            }
            .padding(40)
        }
    }

    func restoreWallet() {
        isValidating = true
        errorMessage = nil

        // First validate the mnemonic
        guard validateMnemonic(phrase) else {
            errorMessage = "Invalid recovery phrase. Check each word and try again."
            isValidating = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let keys = keypairFromMnemonic(phrase) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to derive keypair from phrase."
                    self.isValidating = false
                }
                return
            }

            let validatorId   = keys.validatorId.map   { String(format: "%02x", $0) }.joined()
            let classicalPk   = keys.classicalPk.map   { String(format: "%02x", $0) }.joined()
            let pqPk          = Data(keys.pqPk)
            let classicalSeed = Data(keys.classicalSeed)
            let pqSk          = Data(keys.pqSk)

            // Save keys.json
            let keysJson: [String: Any] = [
                "validator_id": validatorId,
                "public": [
                    "hybrid_classical_pk": classicalPk,
                    "hybrid_pq_pk": pqPk.map { String(format: "%02x", $0) }.joined()
                ],
                "private": [
                    "hybrid_seed": classicalSeed.map { String(format: "%02x", $0) }.joined(),
                    "pq_sk": pqSk.map { String(format: "%02x", $0) }.joined(),
                    "WARNING": "Keep private seeds secret. Never share this file."
                ]
            ]

            do {
                try self.nodeManager.createDataDirectory()
                let data = try JSONSerialization.data(
                    withJSONObject: keysJson, options: .prettyPrinted
                )
                let keysPath = URL(fileURLWithPath: self.nodeManager.keysPath)
                try data.write(to: keysPath)

                // Copy genesis.toml if not present
                let genesisPath = URL(fileURLWithPath: self.nodeManager.genesisPath)
                if !FileManager.default.fileExists(atPath: genesisPath.path) {
                    let candidates = [
                        URL(fileURLWithPath: self.nodeManager.nodeBinaryPath)
                            .deletingLastPathComponent()
                            .appendingPathComponent("genesis.toml"),
                        URL(fileURLWithPath: NSHomeDirectory())
                            .appendingPathComponent("Desktop/project_indra/indra/genesis.toml")
                    ]
                    for candidate in candidates {
                        if FileManager.default.fileExists(atPath: candidate.path) {
                            try FileManager.default.copyItem(at: candidate, to: genesisPath)
                            break
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.walletStore.saveIdentity(
                        validatorId: validatorId,
                        classicalPk: classicalPk
                    )
                    self.isValidating = false
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save keys: \(error.localizedDescription)"
                    self.isValidating = false
                }
            }
        }
    }
}
