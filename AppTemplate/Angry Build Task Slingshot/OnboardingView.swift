import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(asset: "onboarding_plan_illustration", title: "Plan Every Build", message: "Organize projects, budgets, materials and deadlines in one place."),
        OnboardingPage(asset: "onboarding_slingshot_illustration", title: "Launch Tasks Into Done", message: "Pull, release and complete work with the signature Slingshot action."),
        OnboardingPage(asset: "onboarding_budget_illustration", title: "Control Budget & Progress", message: "Track expenses, monitor progress and keep every project readable.")
    ]

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 760
            let illustrationHeight = min(compactHeight ? 220 : 320, proxy.size.height * (compactHeight ? 0.28 : 0.36))

            ZStack {
                AppBackground()
                VStack(spacing: compactHeight ? 14 : 22) {
                    ManagedAssetView(name: "brand_logo", mode: .contain)
                        .frame(width: compactHeight ? 126 : 150, height: compactHeight ? 56 : 78)
                        .padding(.top, compactHeight ? 8 : 18)

                    TabView(selection: $page) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: compactHeight ? 16 : 24) {
                                ManagedAssetView(name: item.asset, mode: .contain)
                                    .frame(height: index == 1 ? min(illustrationHeight, 280) : illustrationHeight)
                                    .padding(.horizontal, 22)
                                VStack(spacing: 12) {
                                    Text(item.title)
                                        .font(compactHeight ? .brandTitle : .brandLargeTitle)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(item.message)
                                        .font(.body)
                                        .foregroundStyle(Theme.mutedText)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 24)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxHeight: .infinity)

                    OnboardingPageIndicator(count: pages.count, selection: page)
                        .padding(.top, compactHeight ? 0 : 4)

                    Button(page == pages.count - 1 ? "Let's Build" : "Next") {
                        if page == pages.count - 1 {
                            onFinish()
                        } else {
                            withAnimation(.snappy) {
                                page += 1
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .accessibilityLabel(page == pages.count - 1 ? "Finish onboarding" : "Next onboarding page")

                    Button("Skip", action: onFinish)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                        .padding(.bottom, compactHeight ? 10 : 18)
                }
            }
        }
    }
}

private struct OnboardingPageIndicator: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? Theme.orange : Color.white.opacity(0.32))
                    .frame(width: index == selection ? 22 : 8, height: 8)
                    .animation(.snappy, value: selection)
            }
        }
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("\(selection + 1) of \(count)")
    }
}

private struct OnboardingPage {
    let asset: String
    let title: String
    let message: String
}
