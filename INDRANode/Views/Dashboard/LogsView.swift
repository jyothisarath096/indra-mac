import SwiftUI
internal import UniformTypeIdentifiers

struct LogsView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @State private var filter: LogFilter = .all
    @State private var autoScroll = true

    enum LogFilter: String, CaseIterable {
        case all      = "ALL"
        case errors   = "ERRORS"
        case blocks   = "BLOCKS"
        case warnings = "WARNINGS"
    }

    var filteredLogs: [LogEntry] {
        switch filter {
        case .all:      return nodeManager.logs
        case .errors:   return nodeManager.logs.filter { $0.level == .error }
        case .blocks:   return nodeManager.logs.filter { $0.level == .block }
        case .warnings: return nodeManager.logs.filter { $0.level == .warn }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 16) {
                Text("LOGS")
                    .font(.indraTitle).tracking(4).foregroundColor(.indraGold)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(LogFilter.allCases, id: \.self) { f in
                        Button(action: { filter = f }) {
                            Text(f.rawValue)
                                .font(.indraMonoSmall).tracking(1)
                                .foregroundColor(filter == f ? .indraGold : .indraMuted)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(filter == f
                                    ? Color.indraGold.opacity(0.1) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .font(.indraMonoSmall).foregroundColor(.indraMuted)
                    .toggleStyle(.checkbox)
                Button(action: saveLogs) {
                    Label("Save", systemImage: "arrow.down.doc")
                        .font(.indraMonoSmall).foregroundColor(.indraMuted)
                }
                .buttonStyle(.plain)
                Button(action: { nodeManager.logs.removeAll() }) {
                    Label("Clear", systemImage: "trash")
                        .font(.indraMonoSmall).foregroundColor(.indraMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
            .background(Color.indraCard)

            Divider().background(Color.indraBorder)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredLogs) { entry in
                            logLine(entry).id(entry.id)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }
                .onChange(of: nodeManager.logs.count) { _ in
                    if autoScroll, let last = filteredLogs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .background(Color.indraBlack)
    }

    func logLine(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.timestamp, style: .time)
                .font(.indraMonoSmall).foregroundColor(.indraMuted.opacity(0.6))
                .frame(width: 80, alignment: .leading)
            Text(entry.message)
                .font(.indraMonoSmall)
                .foregroundColor(lineColor(entry.level))
                .textSelection(.enabled)
        }
        .padding(.vertical, 1)
    }

    func lineColor(_ level: LogEntry.Level) -> Color {
        switch level {
        case .error: return .indraRed
        case .warn:  return .indraGold
        case .block: return .indraGreen
        case .info:  return .indraText.opacity(0.8)
        }
    }

    func saveLogs() {
        let content = nodeManager.logs
            .map { "\($0.timestamp) \($0.message)" }
            .joined(separator: "\n")
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "indra-node-\(Int(Date().timeIntervalSince1970)).log"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
