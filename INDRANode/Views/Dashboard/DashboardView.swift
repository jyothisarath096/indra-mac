import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var nodeManager: NodeManager
    @EnvironmentObject var walletStore: NodeWalletStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.indraBlack.ignoresSafeArea()
            HStack(spacing: 0) {
                sidebar.frame(width: 220)
                Divider().background(Color.indraBorder)
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    var content: some View {
        ZStack {
            switch selectedTab {
            case 0:  MainDashboardView()
            case 1:  LogsView()
            case 2:  SettingsNodeView()
            default: EmptyView()
            }
        }
    }

    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            HStack(spacing: 8) {
                Text("⚡").font(.system(size: 18))
                Text("INDRA NODE")
                    .font(.indraLabel).tracking(4).foregroundColor(.indraText)
            }
            .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 8)

            // Status
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 6, height: 6)
                Text(nodeManager.status.label)
                    .font(.indraMonoSmall).foregroundColor(statusColor)
            }
            .padding(.horizontal, 20).padding(.bottom, 24)

            // Nav
            navItem("square.grid.2x2", "Dashboard", 0)
            navItem("text.alignleft",  "Logs",      1)
            navItem("gearshape",       "Settings",  2)

            Spacer()

            // Start / Stop
            Group {
                if nodeManager.status.isRunning {
                    INDRAButton(
                title: "Stop Node",
                action: { nodeManager.stopNode() },
                style: .destructive
            )
                } else {
                    INDRAButton(title: "Start Node", action: { nodeManager.startNode() })
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
        .background(Color.indraCard)
    }

    func navItem(_ icon: String, _ label: String, _ tab: Int) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(selectedTab == tab ? .indraGold : .indraMuted)
                    .frame(width: 16)
                Text(label.uppercased())
                    .font(.indraLabel).tracking(2)
                    .foregroundColor(selectedTab == tab ? .indraGold : .indraMuted)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(selectedTab == tab ? Color.indraGold.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    var statusColor: Color {
        switch nodeManager.status {
        case .running:  return .indraGreen
        case .starting, .stopping: return .indraGold
        case .stopped:  return .indraMuted
        case .error:    return .indraRed
        }
    }
}
