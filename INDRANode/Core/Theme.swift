import SwiftUI

// MARK: - Colors
extension Color {
    static let indraBlack   = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let indraCard    = Color(red: 0.10, green: 0.09, blue: 0.08)
    static let indraBorder  = Color(white: 0.18)
    static let indraGold    = Color(red: 0.85, green: 0.68, blue: 0.25)
    static let indraGoldDim = Color(red: 0.55, green: 0.44, blue: 0.16)
    static let indraText    = Color(white: 0.92)
    static let indraMuted   = Color(white: 0.45)
    static let indraGreen   = Color(red: 0.25, green: 0.75, blue: 0.45)
    static let indraRed     = Color(red: 0.85, green: 0.28, blue: 0.28)
}

// MARK: - Fonts
extension Font {
    static let indraWordmark  = Font.custom("Courier New", size: 22).bold()
    static let indraTitle     = Font.custom("Courier New", size: 16).bold()
    static let indraLabel     = Font.custom("Courier New", size: 11)
    static let indraBody      = Font.system(size: 13)
    static let indraMono      = Font.custom("Courier New", size: 13)
    static let indraMonoSmall = Font.custom("Courier New", size: 11)
}

// MARK: - Components
struct INDRACard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Color.indraCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.indraBorder, lineWidth: 0.5))
    }
}

struct INDRADivider: View {
    var body: some View {
        Rectangle().fill(Color.indraBorder).frame(height: 0.5)
    }
}

struct INDRASectionLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.indraLabel).tracking(3)
                .foregroundColor(.indraGold)
            Rectangle().fill(Color.indraBorder).frame(height: 0.5)
        }
    }
}

struct INDRAButton: View {
    enum Style { case primary, secondary, destructive }
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.indraLabel).tracking(3)
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(bgColor)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
    }

    private var bgColor: Color {
        switch style {
        case .primary:     return .indraGold.opacity(0.15)
        case .secondary:   return .indraCard
        case .destructive: return .indraRed.opacity(0.15)
        }
    }
    private var borderColor: Color {
        switch style {
        case .primary:     return .indraGold.opacity(0.5)
        case .secondary:   return .indraBorder
        case .destructive: return .indraRed.opacity(0.5)
        }
    }
    private var labelColor: Color {
        switch style {
        case .primary:     return .indraGold
        case .secondary:   return .indraText
        case .destructive: return .indraRed
        }
    }
}

// MARK: - Formatters
func formatINDRA(_ spark: UInt64) -> String {
    let indra = Double(spark) / 100_000_000.0
    if indra >= 1_000_000 { return String(format: "%.2fM", indra / 1_000_000) }
    if indra >= 1_000     { return String(format: "%.2fK", indra / 1_000) }
    return String(format: "%.8f", indra)
}

func shortId(_ hex: String) -> String {
    guard hex.count >= 16 else { return hex }
    return String(hex.prefix(8)) + "..." + String(hex.suffix(6))
}
