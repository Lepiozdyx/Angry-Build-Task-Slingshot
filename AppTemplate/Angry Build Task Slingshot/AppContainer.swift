import SwiftUI

struct AppContainer: View {
    @StateObject private var store: BuildStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let repository = LocalBuildRepository()
        _store = StateObject(wrappedValue: BuildStore(repository: repository))
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                AppRootView()
                    .environmentObject(store)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .task {
            await store.load()
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject private var store: BuildStore
    @State private var selection: AppTab = .projects

    var body: some View {
        ZStack {
            switch selection {
            case .projects:
                NavigationStack {
                    ProjectsDashboardView(selection: $selection)
                }
            case .board:
                NavigationStack {
                    TaskBoardView(selection: $selection)
                }
            case .budget:
                NavigationStack {
                    BudgetView()
                }
            case .analytics:
                NavigationStack {
                    AnalyticsView()
                }
            }
        }
        .padding(.bottom, 72)
        .overlay(alignment: .bottom) {
            AngryBuildTabBar(selection: $selection)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(Theme.orange)
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if let message = store.toastMessage {
                ToastBanner(message: message)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

enum AppTab: Hashable {
    case projects
    case board
    case budget
    case analytics

    var title: String {
        switch self {
        case .projects: "Projects"
        case .board: "Board"
        case .budget: "Budget"
        case .analytics: "Analytics"
        }
    }

    var emoji: String {
        switch self {
        case .projects: "🏗️"
        case .board: "⚡"
        case .budget: "💰"
        case .analytics: "📊"
        }
    }
}
