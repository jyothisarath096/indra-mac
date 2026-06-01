import Foundation
import Combine

enum NodeStatus {
    case stopped
    case starting
    case running
    case stopping
    case error(String)

    var label: String {
        switch self {
        case .stopped:        return "STOPPED"
        case .starting:       return "STARTING"
        case .running:        return "RUNNING"
        case .stopping:       return "STOPPING"
        case .error(let e):   return "ERROR: \(e)"
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: Level
    let timestamp: Date

    enum Level { case info, warn, error, block }
}

class NodeManager: ObservableObject {
    static let shared = NodeManager()

    @Published var status: NodeStatus = .stopped
    @Published var blockHeight: UInt64 = 0
    @Published var connectedPeers: Int = 0
    @Published var currentEpoch: UInt64 = 0
    @Published var activeValidators: Int = 0
    @Published var maxActiveValidators: Int = 20
    @Published var validatorSetPhase: Int = 1
    
    /// Minimum peers needed for consensus (>66% of active set, minus self)
    var peersNeeded: Int {
        let needed = Int(ceil(Double(activeValidators) * 2.0 / 3.0))
        return max(needed - 1, 1) // subtract self
    }
    @Published var logs: [LogEntry] = []
    @Published var sessionNumber: Int = 0
    @Published var diskAvailableGB: Double = 0

    private var process: Process?
    private var logPipe: Pipe?
    private var pollTimer: Timer?
    private var diskTimer: Timer?

    private init() {
        sessionNumber = UserDefaults.standard.integer(forKey: "indra.node.session_count")
        bootstrapPeers = UserDefaults.standard.string(forKey: "indra.node.bootstrap_peers") ?? ""
        checkDiskSpace()
    }

    var nodeBinaryPath: String {
        if let bundled = Bundle.main.path(forResource: "node", ofType: nil) {
            return bundled
        }
        return NSHomeDirectory() + "/Desktop/project_indra/indra/target/release/node"
    }

    var dataDirectory: String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("INDRANode").path
        return dir
    }

    var genesisPath: String { dataDirectory + "/genesis.toml" }
    var keysPath: String    { dataDirectory + "/keys.json" }
    
    @Published var bootstrapPeers: String {
        didSet { UserDefaults.standard.set(bootstrapPeers, forKey: "indra.node.bootstrap_peers") }
    }

    func createDataDirectory() throws {
        try FileManager.default.createDirectory(
            atPath: dataDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Start / Stop
    func startNode() {
        guard !status.isRunning else { return }
        guard FileManager.default.fileExists(atPath: nodeBinaryPath) else {
            status = .error("Node binary not found")
            addLog("ERROR: Node binary not found at \(nodeBinaryPath)", level: .error)
            return
        }
        guard FileManager.default.fileExists(atPath: keysPath) else {
            status = .error("keys.json not found — complete setup first")
            addLog("ERROR: keys.json not found at \(keysPath)", level: .error)
            return
        }

        status = .starting
        
        // Increment session counter and add separator
        let session = UserDefaults.standard.integer(forKey: "indra.node.session_count") + 1
        UserDefaults.standard.set(session, forKey: "indra.node.session_count")
        sessionNumber = session
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · h:mm a"
        let sessionEntry = LogEntry(
            message: "─── SESSION \(session) · Started \(formatter.string(from: Date())) ───────────────────",
            level: .info,
            timestamp: Date()
        )
        DispatchQueue.main.async { self.logs.append(sessionEntry) }
        addLog("Starting INDRA node...", level: .info)

        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: nodeBinaryPath)
        var args = [
            "--data-dir", dataDirectory,
            "--genesis",  genesisPath,
            "--keys",     keysPath,
            "--prune-keep", "50000"
        ]
        let peers = bootstrapPeers.trimmingCharacters(in: .whitespaces)
        if !peers.isEmpty {
            args += ["--bootstrap-peers", peers]
        }
        proc.arguments = args
        proc.standardOutput = pipe
        proc.standardError  = pipe

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.status = .stopped
                self?.addLog("Node process terminated", level: .warn)
                self?.stopPolling()
            }
        }

        // Use readabilityHandler for async pipe reading on macOS
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            guard let output = String(data: data, encoding: .utf8) else { return }
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                DispatchQueue.main.async { self?.parseLine(trimmed) }
            }
        }

        do {
            try proc.run()
            self.process = proc
            self.logPipe  = pipe
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                if case .starting = self.status {
                    self.status = .running
                    self.addLog("Node is running — PID \(proc.processIdentifier)", level: .info)
                    self.startPolling()
                }
            }
        } catch {
            status = .error(error.localizedDescription)
            addLog("Failed to start: \(error.localizedDescription)", level: .error)
        }
    }

    func stopNode() {
        guard status.isRunning else { return }
        status = .stopping
        addLog("Stopping node...", level: .info)
        stopPolling()
        process?.terminate()
        process = nil
        logPipe = nil
    }

    // MARK: - Log parsing
    private func parseLine(_ line: String) {
        let lower = line.lowercased()
        let level: LogEntry.Level
        if lower.contains("error") || lower.contains("fatal") { level = .error }
        else if lower.contains("warn")                         { level = .warn  }
        else if lower.contains("block") || lower.contains("height") { level = .block }
        else                                                   { level = .info  }
        addLog(line, level: level)

        if let range = line.range(of: "height="),
           let numStr = line[range.upperBound...].components(separatedBy: " ").first,
           let h = UInt64(numStr) {
            blockHeight = h
        }
    }

    func addLog(_ message: String, level: LogEntry.Level) {
        let entry = LogEntry(message: message, level: level, timestamp: Date())
        DispatchQueue.main.async {
            self.logs.append(entry)
            if self.logs.count > 1000 { self.logs.removeFirst(100) }
        }
    }

    // MARK: - Polling
    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            self?.pollChainInfo()
        }
        diskTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkDiskSpace()
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate(); pollTimer = nil
        diskTimer?.invalidate(); diskTimer = nil
    }

    private func pollChainInfo() {
        guard let url = URL(string: "http://127.0.0.1:8545") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = #"{"jsonrpc":"2.0","method":"indra_getChainInfo","params":[],"id":1}"#.data(using: .utf8)
        req.timeoutInterval = 4
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any] else { return }
            DispatchQueue.main.async {
                self?.blockHeight         = result["height"] as? UInt64 ?? self?.blockHeight ?? 0
                self?.currentEpoch        = result["epoch"]  as? UInt64 ?? self?.currentEpoch ?? 0
                self?.activeValidators    = result["active_validators"]     as? Int ?? self?.activeValidators ?? 0
                self?.maxActiveValidators = result["max_active_validators"] as? Int ?? self?.maxActiveValidators ?? 20
                self?.validatorSetPhase   = result["validator_set_phase"]   as? Int ?? self?.validatorSetPhase ?? 1
                if case .starting = self?.status ?? .stopped { self?.status = .running }
            }
        }.resume()
    }

    func checkDiskSpace() {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? Int64 {
            let gb = Double(free) / 1_073_741_824
            DispatchQueue.main.async {
                self.diskAvailableGB = gb
                if gb < 0.5 {
                    self.addLog("CRITICAL: \(String(format: "%.1f", gb)) GB disk remaining — node paused", level: .error)
                } else if gb < 5.0 {
                    self.addLog("WARNING: \(String(format: "%.1f", gb)) GB disk remaining", level: .warn)
                }
            }
        }
    }
}
