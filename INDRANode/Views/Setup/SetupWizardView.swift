import SwiftUI

struct SetupWizardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletStore: NodeWalletStore
    @EnvironmentObject var nodeManager: NodeManager

    @State private var step = 0
    @State private var mnemonic: [String] = []
    @State private var confirmedWords = Set<Int>()
    @State private var verifyIndices: [Int] = []
    @State private var verifyInputs = ["", "", ""]
    @State private var verifyError = false
    @State private var generateError: String?

    var body: some View {
        ZStack {
            Color.indraBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(i <= step ? Color.indraGold : Color.indraBorder)
                            .frame(height: 2)
                            .animation(.easeInOut, value: step)
                    }
                }
                .padding(.horizontal, 40).padding(.top, 32)

                Spacer()

                Group {
                    switch step {
                    case 0: generatingView
                    case 1: phraseView
                    case 2: verifyView
                    case 3: systemCheckView
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear { generateKeys() }
    }

    // MARK: - Step 0: Generating
    var generatingView: some View {
        VStack(spacing: 24) {
            if let err = generateError {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40)).foregroundColor(.indraRed)
                Text(err)
                    .font(.indraBody).foregroundColor(.indraRed)
                    .multilineTextAlignment(.center)
            } else {
                ProgressView().scaleEffect(1.5).tint(.indraGold)
                Text("Generating your validator keypair...")
                    .font(.indraBody).foregroundColor(.indraMuted)
            }
        }
    }

    // MARK: - Step 1: Show phrase
    var phraseView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("YOUR RECOVERY PHRASE")
                    .font(.indraTitle).foregroundColor(.indraGold)
                Text("Write these 24 words down and store them safely. They are your validator identity and wallet. Anyone with these words controls your funds.")
                    .font(.indraBody).foregroundColor(.indraMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                spacing: 6
            ) {
                ForEach(Array(mnemonic.enumerated()), id: \.offset) { i, word in
                    Button(action: { confirmedWords.insert(i) }) {
                        VStack(spacing: 2) {
                            Text("\(i + 1)")
                                .font(.system(size: 9)).foregroundColor(.indraMuted)
                            Text(word)
                                .font(.indraMonoSmall)
                                .foregroundColor(confirmedWords.contains(i)
                                    ? .indraGold : .indraText)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(confirmedWords.contains(i)
                            ? Color.indraGold.opacity(0.1) : Color.indraCard)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(confirmedWords.contains(i)
                                ? Color.indraGold.opacity(0.4) : Color.indraBorder,
                                    lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tap each word to confirm you've written it down (\(confirmedWords.count)/24)")
                .font(.indraMonoSmall).foregroundColor(.indraMuted)

            INDRAButton(
                title: "I've Written All 24 Words",
                action: { generateVerifyIndices(); step = 2 },
                disabled: confirmedWords.count < 24
            )
        }
    }

    // MARK: - Step 2: Verify
    var verifyView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("VERIFY YOUR PHRASE")
                    .font(.indraTitle).foregroundColor(.indraGold)
                Text("Enter the words at the positions below to confirm you've saved your recovery phrase.")
                    .font(.indraBody).foregroundColor(.indraMuted)
            }

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 16) {
                        Text("Word #\(verifyIndices.indices.contains(i) ? verifyIndices[i] + 1 : 0)")
                            .font(.indraMono).foregroundColor(.indraMuted)
                            .frame(width: 90, alignment: .leading)
                        TextField("Enter word", text: $verifyInputs[i])
                            .textFieldStyle(.plain).font(.indraMono)
                            .foregroundColor(.indraText)
                            .padding(10).background(Color.indraCard).cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4)
                                .stroke(verifyError
                                    ? Color.indraRed.opacity(0.5) : Color.indraBorder,
                                        lineWidth: 0.5))
                            .autocorrectionDisabled()
                    }
                }
            }

            if verifyError {
                Text("Incorrect words. Check your phrase and try again.")
                    .font(.indraMonoSmall).foregroundColor(.indraRed)
            }

            INDRAButton(title: "Verify Phrase", action: { verifyPhrase() })
        }
    }

    // MARK: - Step 3: System check
    var systemCheckView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SYSTEM CHECK")
                    .font(.indraTitle).foregroundColor(.indraGold)
                Text("Verifying your system can run an INDRA validator node.")
                    .font(.indraBody).foregroundColor(.indraMuted)
            }

            INDRACard {
                VStack(alignment: .leading, spacing: 12) {
                    checkRow("macOS Version",
                             ProcessInfo.processInfo.operatingSystemVersionString,
                             pass: true)
                    INDRADivider()
                    checkRow("Available Disk",
                             String(format: "%.1f GB", nodeManager.diskAvailableGB),
                             pass: nodeManager.diskAvailableGB >= 10)
                    INDRADivider()
                    checkRow("Node Binary",
                             FileManager.default.fileExists(atPath: nodeManager.nodeBinaryPath)
                                ? "Found" : "Not found — compile first",
                             pass: FileManager.default.fileExists(atPath: nodeManager.nodeBinaryPath))
                    INDRADivider()
                    checkRow("Data Directory", nodeManager.dataDirectory, pass: true)
                    INDRADivider()
                    checkRow("Keys Generated",
                             mnemonic.count == 24 ? "Ready — 24 words generated" : "Pending",
                             pass: mnemonic.count == 24)
                }
            }

            INDRAButton(title: "Complete Setup — Start Validating",
                        action: { completeSetup() })
        }
    }

    func checkRow(_ label: String, _ value: String, pass: Bool) -> some View {
        HStack {
            Image(systemName: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(pass ? .indraGreen : .indraRed)
                .font(.system(size: 14))
            Text(label).font(.indraBody).foregroundColor(.indraText)
            Spacer()
            Text(value)
                .font(.indraMonoSmall).foregroundColor(.indraMuted)
                .lineLimit(1).truncationMode(.middle)
        }
    }

    // MARK: - Logic
    func generateKeys() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let phrase = generateMnemonic() else {
                DispatchQueue.main.async {
                    self.generateError = "Failed to generate mnemonic. Check FFI linkage."
                }
                return
            }
            let words = phrase.components(separatedBy: " ")
            guard words.count == 24 else {
                DispatchQueue.main.async {
                    self.generateError = "Generated phrase has \(words.count) words (expected 24)."
                }
                return
            }
            DispatchQueue.main.async {
                self.mnemonic = words
                self.step = 1
            }
        }
    }

    func generateVerifyIndices() {
        var set = Set<Int>()
        while set.count < 3 { set.insert(Int.random(in: 0..<24)) }
        verifyIndices = Array(set).sorted()
    }

    func verifyPhrase() {
        verifyError = false
        for i in 0..<3 {
            guard verifyIndices.indices.contains(i) else { verifyError = true; return }
            if verifyInputs[i].lowercased().trimmingCharacters(in: .whitespaces)
                != mnemonic[verifyIndices[i]] {
                verifyError = true; return
            }
        }
        nodeManager.checkDiskSpace()
        step = 3
    }

    func completeSetup() {
        let phrase = mnemonic.joined(separator: " ")
        DispatchQueue.global(qos: .userInitiated).async {
            guard let keys = keypairFromMnemonic(phrase) else {
                DispatchQueue.main.async {
                    self.generateError = "Failed to derive keypair from phrase."
                }
                return
            }

            let validatorId = keys.validatorId.map { String(format: "%02x", $0) }.joined()
            let classicalPk = keys.classicalPk.map { String(format: "%02x", $0) }.joined()
            let pqPk        = Data(keys.pqPk)
            let classicalSeed = Data(keys.classicalSeed)
            let blsSeed     = Data(keys.blsSeed)
            let vrfSeed     = Data(keys.vrfSeed)
            let pqSk        = Data(keys.pqSk)

            // Save keys.json to data directory
            let keysJson: [String: Any] = [
                "validator_id": validatorId,
                "public": [
                    "hybrid_classical_pk": classicalPk,
                    "hybrid_pq_pk": pqPk.map { String(format: "%02x", $0) }.joined()
                ],
                "private": [
                    "hybrid_seed": classicalSeed.map { String(format: "%02x", $0) }.joined(),
                    "bls_seed": blsSeed.map { String(format: "%02x", $0) }.joined(),
                    "vrf_seed": vrfSeed.map { String(format: "%02x", $0) }.joined(),
                    "pq_sk": pqSk.map { String(format: "%02x", $0) }.joined(),
                    "WARNING": "Keep private seeds secret. Never share this file."
                ]
            ]

            do {
                try self.nodeManager.createDataDirectory()
                // Use sortedKeys only — no prettyPrinted (adds spaces around colons
                // which breaks the node's naive key parser)
                let data = try JSONSerialization.data(
                    withJSONObject: keysJson, options: .sortedKeys
                )
                let keysPath = URL(fileURLWithPath: self.nodeManager.keysPath)
                try data.write(to: keysPath)

                // Also copy genesis.toml if not present
                let genesisPath = URL(fileURLWithPath: self.nodeManager.genesisPath)
                if !FileManager.default.fileExists(atPath: genesisPath.path) {
                    // Look for genesis.toml next to node binary
                    let binaryDir = URL(fileURLWithPath: self.nodeManager.nodeBinaryPath)
                        .deletingLastPathComponent()
                    let candidates = [
                        binaryDir.appendingPathComponent("genesis.toml"),
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
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.generateError = "Failed to save keys: \(error.localizedDescription)"
                }
            }
        }
    }
}
