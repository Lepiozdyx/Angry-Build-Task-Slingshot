import SwiftUI

enum Theme {
    static let background = Color(red: 0.035, green: 0.062, blue: 0.12)
    static let panel = Color(red: 0.105, green: 0.075, blue: 0.065)
    static let panelRaised = Color(red: 0.235, green: 0.115, blue: 0.07)
    static let field = Color(red: 0.095, green: 0.105, blue: 0.14)
    static let orange = Color(red: 1.0, green: 0.39, blue: 0.055)
    static let yellow = Color(red: 1.0, green: 0.76, blue: 0.02)
    static let green = Color(red: 0.05, green: 0.78, blue: 0.36)
    static let blue = Color(red: 0.22, green: 0.52, blue: 1.0)
    static let mutedText = Color.white.opacity(0.62)
    static let border = Color.orange.opacity(0.24)
    static let softBorder = Color.white.opacity(0.08)
}

extension Font {
    static func carter(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom("CarterOne", size: size, relativeTo: textStyle)
    }

    static var brandLargeTitle: Font {
        .carter(34, relativeTo: .largeTitle)
    }

    static var brandTitle: Font {
        .carter(24, relativeTo: .title2)
    }

    static var brandHeadline: Font {
        .carter(17, relativeTo: .headline)
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let uiImage = UIImage(named: "app_background") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.28)
                    .ignoresSafeArea()
            }
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.clear, Theme.orange.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

struct Panel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.panelRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            )
    }
}

struct AngryBuildTabBar: View {
    @Binding var selection: AppTab

    private let tabs: [AppTab] = [.projects, .board, .budget, .analytics]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.emoji)
                            .font(.system(size: 21))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(selection == tab ? .carter(12, relativeTo: .caption) : .caption)
                    }
                    .foregroundStyle(selection == tab ? Theme.orange : Theme.mutedText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.panelRaised.opacity(0.92))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            Color(red: 0.025, green: 0.045, blue: 0.085)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.border).frame(height: 0.6)
                }
                .ignoresSafeArea()
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.orange)
                    .shadow(color: Theme.orange.opacity(configuration.isPressed ? 0.15 : 0.45), radius: 18, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Animation.easeInOut(duration: 0.16), value: configuration.isPressed)
            .accessibilityAddTraits(AccessibilityTraits.isButton)
    }
}

struct RoundIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.mutedText)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(Theme.softBorder))
        }
        .buttonStyle(.plain)
    }
}

struct TopActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.carter(14, relativeTo: .subheadline))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(Theme.orange)
                        .shadow(color: Theme.orange.opacity(0.48), radius: 15, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.carter(15, relativeTo: .subheadline))
            .foregroundStyle(Theme.orange)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.08 : 0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border))
            )
    }
}

struct ProgressBar: View {
    var value: Double
    var tint: Color = Theme.yellow

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.16))
                Capsule()
                    .fill(LinearGradient(colors: [Theme.orange, tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(value * 100)) percent")
    }
}

enum AssetScaleMode {
    case cover
    case contain
    case fill
}

struct ManagedAssetView: View {
    let name: String
    let mode: AssetScaleMode

    var body: some View {
        GeometryReader { proxy in
            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .modifier(AssetScalingModifier(mode: mode))
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.55)
                        .padding(.horizontal, 8)
                }
                .foregroundStyle(Theme.mutedText)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                        .foregroundStyle(Color.white.opacity(0.32))
                )
                .accessibilityLabel("Missing image asset \(name)")
            }
        }
    }
}

private struct AssetScalingModifier: ViewModifier {
    let mode: AssetScaleMode

    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill()
        case .contain:
            content.scaledToFit()
        case .fill:
            content
        }
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Theme.orange)
            Text(title)
                .font(.brandTitle)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 6)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.carter(15, relativeTo: .subheadline))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 12)
    }
}

struct FieldLabel: View {
    let title: String
    var isRequired = false

    var body: some View {
        HStack(spacing: 2) {
            Text(title.uppercased())
            if isRequired {
                Text("*")
                    .foregroundStyle(Theme.orange)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.mutedText)
    }
}

extension View {
    func screenBackground() -> some View {
        background(AppBackground())
    }

    func keyboardToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

extension Array where Element == ExpenseItem {
    func total() -> Decimal {
        reduce(Decimal(0)) { $0 + $1.amount }
    }
}

extension BuildProject {
    func formattedBudget(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.maximumFractionDigits = amount.doubleValue >= 1000 ? 0 : 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency.symbol)\(amount)"
    }
}
