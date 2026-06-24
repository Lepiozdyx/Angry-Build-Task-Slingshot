import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProjectsDashboardView: View {
    @EnvironmentObject private var store: BuildStore
    @Binding var selection: AppTab
    @State private var isCreatingProject = false
    @State private var filter: ProjectFilter = .all
    @State private var query = ""

    private var filteredProjects: [BuildProject] {
        store.projects.filter { project in
            let matchesQuery = query.isEmpty || project.name.localizedCaseInsensitiveContains(query) || project.address.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = !project.isArchived
            case .urgent:
                matchesFilter = urgentTaskCount(for: project) > 0
            }
            return matchesQuery && matchesFilter
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if store.isLoading {
                        ProgressView("Loading build data...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if store.projects.isEmpty {
                        EmptyStateView(
                            systemImage: "building.2.crop.circle",
                            title: "No projects yet",
                            message: "Create your first build object to start planning tasks, budget and progress.",
                            actionTitle: "Create Project"
                        ) {
                            isCreatingProject = true
                        }
                    } else {
                        summary
                        searchAndFilters
                        VStack(spacing: 14) {
                            ForEach(filteredProjects) { project in
                                NavigationLink {
                                    ProjectDetailView(projectID: project.id, selection: $selection)
                                } label: {
                                    ProjectCard(project: project, progress: progress(for: project), spent: spent(for: project), urgentCount: urgentTaskCount(for: project))
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    store.selectProject(project)
                                })
                            }
                        }
                        if filteredProjects.isEmpty {
                            EmptyStateView(systemImage: "line.3.horizontal.decrease.circle", title: "No matching projects", message: "Try another search or filter.", actionTitle: nil, action: nil)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isCreatingProject) {
            ProjectFormView()
        }
        .alert("Storage issue", isPresented: Binding(get: { store.errorMessage != nil }, set: { _ in store.errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Projects")
                    .font(.brandLargeTitle)
                Text("Construction management")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer()
            TopActionButton(title: "+ New") {
                isCreatingProject = true
            }
            .padding(.top, 1)
        }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            MetricCard(title: "Active Projects", value: "\(store.projects.filter { !$0.isArchived }.count)", tint: Theme.orange, minHeight: 92)
            MetricCard(title: "Total Budget", value: compactMoney(store.projects.reduce(Decimal(0)) { $0 + $1.plannedBudget }, currency: store.projects.first?.currency ?? .usd), subtitle: "\(compactMoney(store.expenses.total(), currency: store.projects.first?.currency ?? .usd)) spent", tint: Theme.yellow, minHeight: 92)
        }
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.mutedText)
                TextField("Search projects...", text: $query)
                    .textInputAutocapitalization(.words)
                    .font(.body)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.07)))

            HStack(spacing: 8) {
                ForEach(ProjectFilter.allCases) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(filter == item ? Theme.orange : Theme.mutedText)
                            .padding(.horizontal, 13)
                            .frame(height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(filter == item ? Theme.orange.opacity(0.18) : Color.white.opacity(0.07))
                                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(filter == item ? Theme.border : Color.clear))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .keyboardToolbar()
    }

    private func progress(for project: BuildProject) -> Double {
        let projectTasks = store.tasks.filter { $0.projectID == project.id }
        guard !projectTasks.isEmpty else { return 0 }
        return Double(projectTasks.filter { $0.status == .done }.count) / Double(projectTasks.count)
    }

    private func spent(for project: BuildProject) -> Decimal {
        store.expenses.filter { $0.projectID == project.id }.total()
    }

    private func urgentTaskCount(for project: BuildProject) -> Int {
        store.tasks.filter { task in
            task.projectID == project.id && task.status != .done && (task.priority == .critical || task.priority == .high || task.deadline < Date())
        }.count
    }
}

enum ProjectFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case urgent

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct ProjectDetailView: View {
    @EnvironmentObject private var store: BuildStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    @Binding var selection: AppTab

    private var project: BuildProject? {
        store.projects.first { $0.id == projectID }
    }

    var body: some View {
        ZStack {
            AppBackground()
            if let project {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailHeader(project)

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading) {
                                        Text("Overall Progress")
                                            .foregroundStyle(Theme.mutedText)
                                        Text("\(Int(progress * 100))%")
                                            .font(.carter(40, relativeTo: .largeTitle))
                                            .foregroundStyle(Theme.orange)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Days Left")
                                            .foregroundStyle(Theme.mutedText)
                                        Text("\(max(0, Calendar.current.dateComponents([.day], from: Date(), to: project.deadline).day ?? 0))")
                                            .font(.carter(36, relativeTo: .largeTitle))
                                            .foregroundStyle(Theme.yellow)
                                    }
                                }
                                ProgressBar(value: progress)
                                HStack {
                                    Text("Client: \(project.clientName.isEmpty ? "Not set" : project.clientName)")
                                    Spacer()
                                    Text("Budget: \(Int(budgetUsage * 100))% used")
                                        .foregroundStyle(budgetUsage > 0.85 ? .red : Theme.green)
                                }
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricCard(title: "Total Tasks", value: "\(projectTasks.count)", tint: Theme.orange)
                            MetricCard(title: "Completed", value: "\(projectTasks.filter { $0.status == .done }.count)", tint: Theme.green)
                            MetricCard(title: "In Progress", value: "\(projectTasks.filter { $0.status == .inProgress }.count)", tint: Theme.blue)
                            MetricCard(title: "Budget Used", value: project.formattedBudget(spent), tint: Theme.yellow)
                        }

                        Text("QUICK ACTIONS")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.mutedText)
                        VStack(spacing: 10) {
                            Button {
                                store.selectProject(project)
                                selection = .board
                            } label: {
                                QuickActionRow(icon: "bolt.fill", title: "Open Construction Board", subtitle: "\(projectTasks.filter { $0.status == .todo }.count) tasks to do · \(projectTasks.filter { $0.status == .inProgress }.count) in progress", tint: Theme.orange)
                            }
                            Button {
                                store.selectProject(project)
                                selection = .budget
                            } label: {
                                QuickActionRow(icon: "dollarsign.circle.fill", title: "Budget & Procurement", subtitle: "\(project.formattedBudget(spent)) of \(project.formattedBudget(project.plannedBudget)) spent", tint: Theme.yellow)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
            } else {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "Project not found", message: "The selected project is no longer available.", actionTitle: nil, action: nil)
                    .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func detailHeader(_ project: BuildProject) -> some View {
        HStack(alignment: .center, spacing: 10) {
            RoundIconButton(systemName: "arrow.left") {
                dismiss()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.brandTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Label(project.address, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
            }
        }
    }

    private var projectTasks: [BuildTaskItem] {
        store.tasks.filter { $0.projectID == projectID }
    }

    private var spent: Decimal {
        store.expenses.filter { $0.projectID == projectID }.total()
    }

    private var progress: Double {
        guard !projectTasks.isEmpty else { return 0 }
        return Double(projectTasks.filter { $0.status == .done }.count) / Double(projectTasks.count)
    }

    private var budgetUsage: Double {
        guard let project, project.plannedBudget > 0 else { return 0 }
        return spent.doubleValue / project.plannedBudget.doubleValue
    }
}

struct TaskBoardView: View {
    @EnvironmentObject private var store: BuildStore
    @Binding var selection: AppTab
    @State private var isCreatingTask = false

    var body: some View {
        ZStack {
            AppBackground()
            if let project = store.selectedProject {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        boardHeader(project)
                        boardHint

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(BuildTaskStatus.allCases) { status in
                                    TaskColumn(status: status, tasks: store.selectedProjectTasks.filter { $0.status == status }, onAddTask: {
                                        isCreatingTask = true
                                    })
                                    .frame(width: 220)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
            } else {
                EmptyStateView(systemImage: "rectangle.stack.badge.plus", title: "No project selected", message: "Create a project first, then the construction board will be ready.", actionTitle: nil, action: nil)
                    .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isCreatingTask) {
            TaskFormView()
        }
    }

    private func boardHeader(_ project: BuildProject) -> some View {
        HStack(alignment: .center, spacing: 10) {
            RoundIconButton(systemName: "arrow.left") {
                selection = .projects
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Construction Board")
                    .font(.brandHeadline)
                    .lineLimit(1)
                Text(project.name)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(store.selectedProjectTasks.count) tasks")
                .font(.carter(12, relativeTo: .caption))
                .foregroundStyle(Theme.orange)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(Theme.orange.opacity(0.16), in: Capsule())
                .overlay(Capsule().stroke(Theme.border))
        }
    }

    private var boardHint: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "target")
                .foregroundStyle(Theme.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Tap SLINGSHOT LAUNCH")
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.orange)
                Text("on any TO DO card to complete it")
                    .foregroundStyle(Theme.mutedText)
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.65)))
    }
}

struct BudgetView: View {
    @EnvironmentObject private var store: BuildStore
    @State private var isAddingExpense = false

    var body: some View {
        ZStack {
            AppBackground()
            if let project = store.selectedProject {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        budgetHeader
                        projectChips
                        budgetSummary(project)
                        Text("CATEGORY BREAKDOWN")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.mutedText)
                        Panel {
                            VStack(spacing: 14) {
                                ForEach(ExpenseCategory.allCases.filter { $0 != .other }) { category in
                                    CategorySpendRow(category: category, amount: categoryAmount(category), total: max(store.selectedProjectExpenses.total().doubleValue, 1), currency: project.currency)
                                }
                            }
                        }
                        HStack {
                            Text("EXPENSES (\(store.selectedProjectExpenses.count))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.mutedText)
                            Spacer()
                        }
                        if store.selectedProjectExpenses.isEmpty {
                            EmptyStateView(systemImage: "receipt", title: "No expenses yet", message: "Add receipts, supplier payments or material purchases to track this budget.", actionTitle: "Add Expense") {
                                isAddingExpense = true
                            }
                        } else {
                            ForEach(store.selectedProjectExpenses.sorted(by: { $0.date > $1.date })) { expense in
                                ExpenseRow(expense: expense, currency: project.currency)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
            } else {
                EmptyStateView(systemImage: "dollarsign.circle", title: "No budget to show", message: "Create a project before tracking procurement and expenses.", actionTitle: nil, action: nil)
                    .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isAddingExpense) {
            ExpenseFormView()
        }
    }

    private var budgetHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Budget")
                    .font(.brandLargeTitle)
                Text("& Procurement")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer()
            BudgetTopActionButton(title: "+ Expense") {
                isAddingExpense = true
            }
            .padding(.top, 1)
        }
    }

    private var projectChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.projects) { project in
                    Button {
                        store.selectProject(project)
                    } label: {
                        Text(project.name)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(store.selectedProjectID == project.id ? Theme.yellow : Theme.mutedText)
                            .padding(.horizontal, 12)
                            .frame(height: 31)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(store.selectedProjectID == project.id ? Theme.yellow.opacity(0.12) : Color.white.opacity(0.07))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(store.selectedProjectID == project.id ? Theme.yellow.opacity(0.5) : Color.clear))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func budgetSummary(_ project: BuildProject) -> some View {
        let spent = store.selectedProjectExpenses.total()
        let remaining = project.plannedBudget - spent
        return Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text(project.name.uppercased())
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                HStack {
                    BudgetMetric(title: "Planned", value: project.formattedBudget(project.plannedBudget), tint: Theme.yellow)
                    BudgetMetric(title: "Spent", value: project.formattedBudget(spent), tint: Theme.orange)
                    BudgetMetric(title: "Remaining", value: project.formattedBudget(max(Decimal(0), remaining)), tint: Theme.green)
                }
                ProgressBar(value: project.plannedBudget > 0 ? spent.doubleValue / project.plannedBudget.doubleValue : 0)
                Text("\(Int((project.plannedBudget > 0 ? spent.doubleValue / project.plannedBudget.doubleValue : 0) * 100))% of budget used")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 116, alignment: .top)
        }
    }

    private func categoryAmount(_ category: ExpenseCategory) -> Decimal {
        store.selectedProjectExpenses.filter { $0.category == category }.total()
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var store: BuildStore

    var body: some View {
        ZStack {
            AppBackground()
            if store.projects.isEmpty {
                EmptyStateView(systemImage: "chart.xyaxis.line", title: "Analytics need projects", message: "Create projects and tasks to see performance, budget and progress charts.", actionTitle: nil, action: nil)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        analyticsHeader
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "Active Projects", value: "\(store.projects.filter { !$0.isArchived }.count)", tint: Theme.orange, minHeight: 92)
                            MetricCard(title: "Total Budget", value: compactMoney(store.projects.reduce(Decimal(0)) { $0 + $1.plannedBudget }, currency: store.projects.first?.currency ?? .usd), tint: Theme.yellow, minHeight: 92)
                            MetricCard(title: "Completion Rate", value: "\(Int(completionRate * 100))%", tint: Theme.green, minHeight: 92)
                            MetricCard(title: "Avg Progress", value: "\(Int(averageProgress * 100))%", tint: Theme.blue, minHeight: 92)
                        }
                        ChartPanel(title: "Weekly Task Completion", values: weeklyTaskCompletion, xLabels: weekLabels, yLabels: ["12", "9", "6", "3", "0"], tint: Theme.orange, style: .line, emptyMessage: "Complete tasks to build weekly history.")
                        ChartPanel(title: "Weekly Budget Spend ($)", values: weeklyBudgetSpend, xLabels: weekLabels, yLabels: ["60k", "45k", "30k", "15k", "0k"], tint: Theme.yellow, style: .bars, emptyMessage: "Add expenses to see weekly spend.")
                        ChartPanel(title: "Task Burndown (This Week)", values: taskBurndown, xLabels: dayLabels, yLabels: ["28", "21", "14", "7", "0"], tint: Theme.green, secondaryTint: .cyan, style: .line, emptyMessage: "Create tasks to see this week's burndown.")
                        ExpenseCategoriesPanel(categories: categoryBreakdown, currency: store.projects.first?.currency ?? .usd)
                        Text("PROJECT PROGRESS")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.mutedText)
                        ForEach(store.projects) { project in
                            AnalyticsProjectProgressRow(project: project, progress: progress(for: project))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var analyticsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Analytics")
                .font(.brandLargeTitle)
            Text("Cross-project performance")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
        }
        .padding(.bottom, 4)
    }

    private var completionRate: Double {
        guard !store.tasks.isEmpty else { return 0 }
        return Double(store.tasks.filter { $0.status == .done }.count) / Double(store.tasks.count)
    }

    private var averageProgress: Double {
        guard !store.projects.isEmpty else { return 0 }
        let total = store.projects.reduce(0.0) { $0 + progress(for: $1) }
        return total / Double(store.projects.count)
    }

    private func progress(for project: BuildProject) -> Double {
        let projectTasks = store.tasks.filter { $0.projectID == project.id }
        guard !projectTasks.isEmpty else { return 0 }
        return Double(projectTasks.filter { $0.status == .done }.count) / Double(projectTasks.count)
    }

    private var categoryBreakdown: [(ExpenseCategory, Decimal)] {
        ExpenseCategory.allCases.map { category in
            (category, store.expenses.filter { $0.category == category }.total())
        }
    }

    private var weekLabels: [String] {
        ["W1", "W2", "W3", "W4", "W5", "W6"]
    }

    private var dayLabels: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    private var weeklyTaskCompletion: [Double] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).map { offset in
            guard let week = calendar.date(byAdding: .weekOfYear, value: offset - 5, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: week) else {
                return 0
            }
            return Double(store.tasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return interval.contains(completedAt)
            }.count)
        }
    }

    private var weeklyBudgetSpend: [Double] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).map { offset in
            guard let week = calendar.date(byAdding: .weekOfYear, value: offset - 5, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: week) else {
                return 0
            }
            return store.expenses
                .filter { interval.contains($0.date) }
                .reduce(0.0) { $0 + $1.amount.doubleValue / 1000.0 }
        }
    }

    private var taskBurndown: [Double] {
        let calendar = Calendar.current
        guard !store.tasks.isEmpty,
              let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return Array(repeating: 0, count: 7)
        }
        return (0..<7).map { dayOffset in
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return 0
            }
            return Double(store.tasks.filter { task in
                task.createdAt < dayEnd && (task.completedAt.map { $0 >= dayStart } ?? true)
            }.count)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String?
    let tint: Color
    var minHeight: CGFloat = 76

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.brandTitle)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(14)
        .background(Theme.panelRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
    }
}

struct ProjectCard: View {
    let project: BuildProject
    let progress: Double
    let spent: Decimal
    let urgentCount: Int

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.brandHeadline)
                        Label(project.address, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                    }
                    Spacer()
                    if urgentCount > 0 {
                        Text("\(urgentCount) urgent")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.28), in: Capsule())
                            .foregroundStyle(.red)
                    }
                }
                Rectangle()
                    .fill(Color.white.opacity(0.035))
                    .frame(height: 1)
                    .padding(.horizontal, -16)
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .foregroundStyle(Theme.orange)
                        .fontWeight(.bold)
                }
                .font(.caption)
                ProgressBar(value: progress)
                HStack(spacing: 10) {
                    ProjectMiniMetric(title: "Deadline", value: deadlineText)
                    ProjectMiniMetric(title: "Budget", value: "\(Int(budgetUsage * 100))% used")
                    ProjectMiniMetric(title: "Remaining", value: project.formattedBudget(max(Decimal(0), project.plannedBudget - spent)))
                }
            }
        }
    }

    private var budgetUsage: Double {
        guard project.plannedBudget > 0 else { return 0 }
        return spent.doubleValue / project.plannedBudget.doubleValue
    }

    private var deadlineText: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: project.deadline).day ?? 0
        return days < 0 ? "Overdue" : "\(days)d left"
    }
}

struct ProjectMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isPrimary ? Theme.yellow : tint)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brandHeadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isPrimary ? Color.white.opacity(0.82) : Theme.mutedText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(isPrimary ? Color.white.opacity(0.9) : Theme.mutedText)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(
            isPrimary ? Theme.orange : Theme.panelRaised,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isPrimary ? Color.clear : Theme.border))
    }

    private var isPrimary: Bool {
        title == "Open Construction Board"
    }
}

struct BudgetMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.brandHeadline)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
    }
}

struct BudgetTopActionButton: View {
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
                        .fill(Theme.yellow)
                        .shadow(color: Theme.yellow.opacity(0.46), radius: 15, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct CategorySpendRow: View {
    let category: ExpenseCategory
    let amount: Decimal
    let total: Double
    let currency: BuildCurrency

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Label(category.rawValue, systemImage: category.symbol)
                Spacer()
                Text("\(Int((amount.doubleValue / total) * 100))%")
                    .foregroundStyle(Theme.mutedText)
                Text(formatMoney(amount, currency: currency))
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            ProgressBar(value: amount.doubleValue / total, tint: color)
        }
    }

    private var color: Color {
        switch category {
        case .materials: Theme.orange
        case .labor: Theme.blue
        case .delivery: .purple
        case .equipment: Theme.yellow
        case .other: .gray
        }
    }
}

struct ExpenseRow: View {
    let expense: ExpenseItem
    let currency: BuildCurrency

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbol)
                .foregroundStyle(categoryColor)
                .frame(width: 44, height: 44)
                .background(categoryColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(categoryColor.opacity(0.22)))
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(expense.supplier.isEmpty ? "No supplier" : expense.supplier) · \(expense.date.formatted(date: .numeric, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer()
            Text(formatMoney(expense.amount, currency: currency))
                .font(.headline.weight(.black))
                .foregroundStyle(Theme.yellow)
        }
        .padding(14)
        .frame(minHeight: 74)
        .background(Theme.panelRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
    }

    private var categoryColor: Color {
        switch expense.category {
        case .materials: Theme.orange
        case .labor: Theme.blue
        case .delivery: .purple
        case .equipment: Theme.yellow
        case .other: .gray
        }
    }
}

struct ChartPanel: View {
    enum Style {
        case line
        case bars
    }

    let title: String
    let values: [Double]
    let xLabels: [String]
    let yLabels: [String]
    let tint: Color
    var secondaryTint: Color?
    let style: Style
    let emptyMessage: String

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline.weight(.semibold))
                ChartCanvas(values: values, xLabels: xLabels, yLabels: yLabels, tint: tint, secondaryTint: secondaryTint, style: style, emptyMessage: emptyMessage)
                    .frame(height: 156)
            }
            .frame(maxWidth: .infinity, minHeight: 224, alignment: .topLeading)
        }
    }
}

struct ChartCanvas: View {
    let values: [Double]
    let xLabels: [String]
    let yLabels: [String]
    let tint: Color
    var secondaryTint: Color?
    let style: ChartPanel.Style
    let emptyMessage: String

    private var hasData: Bool {
        values.contains { $0 > 0 }
    }

    private var maxValue: Double {
        max(values.max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(Array(yLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(Theme.mutedText)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(width: 36, height: 124)

            VStack(spacing: 6) {
                GeometryReader { proxy in
                    ZStack {
                        GridLines()
                        if hasData {
                            switch style {
                            case .bars:
                                barPlot(in: proxy.size)
                            case .line:
                                linePlot(in: proxy.size)
                            }
                        } else {
                            Text(emptyMessage)
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 124)

                HStack(spacing: 0) {
                    ForEach(Array(xLabels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(Theme.mutedText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 18)
            }
        }
    }

    private func barPlot(in size: CGSize) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(tint)
                    .frame(height: max(4, size.height * CGFloat(value / maxValue)))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .bottomLeading)
    }

    private func linePlot(in size: CGSize) -> some View {
        ZStack {
            Path { path in
                for (index, value) in values.enumerated() {
                    let x = values.count <= 1 ? 0 : size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let y = size.height - size.height * CGFloat(value / maxValue)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(colors: [secondaryTint ?? tint, tint], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

struct GridLines: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                for i in 0...4 {
                    let y = proxy.size.height * CGFloat(i) / 4
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
                for i in 0...5 {
                    let x = proxy.size.width * CGFloat(i) / 5
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }
            }
            .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
        }
    }
}

struct ExpenseCategoriesPanel: View {
    let categories: [(ExpenseCategory, Decimal)]
    let currency: BuildCurrency

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Expense Categories")
                    .font(.headline.weight(.semibold))
                HStack(spacing: 18) {
                    DonutChart(categories: categories)
                        .frame(width: 126, height: 126)

                    VStack(spacing: 10) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { _, item in
                            let category = item.0
                            let amount = item.1
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color(for: category))
                                    .frame(width: 10, height: 10)
                                Text(category.rawValue)
                                    .foregroundStyle(Theme.mutedText)
                                    .lineLimit(1)
                                Spacer()
                                Text(compactMoney(amount, currency: currency))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .materials: Theme.orange
        case .labor: Theme.blue
        case .delivery: .purple
        case .equipment: Theme.yellow
        case .other: .gray
        }
    }
}

struct DonutChart: View {
    let categories: [(ExpenseCategory, Decimal)]

    private var total: Double {
        categories.reduce(0) { $0 + max(0, $1.1.doubleValue) }
    }

    var body: some View {
        ZStack {
            if total <= 0 {
                Circle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 20)
            } else {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(color(for: segment.category), style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
            Circle()
                .fill(Theme.panelRaised)
                .frame(width: 58, height: 58)
        }
    }

    private var segments: [(category: ExpenseCategory, start: CGFloat, end: CGFloat)] {
        var cursor: CGFloat = 0
        return categories.compactMap { category, amount in
            let value = max(0, amount.doubleValue)
            guard total > 0, value > 0 else { return nil }
            let start = cursor
            let end = cursor + CGFloat(value / total)
            cursor = end
            return (category, start, min(end, 1))
        }
    }

    private func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .materials: Theme.orange
        case .labor: Theme.blue
        case .delivery: .purple
        case .equipment: Theme.yellow
        case .other: .gray
        }
    }
}

struct AnalyticsProjectProgressRow: View {
    let project: BuildProject
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.name)
                    .font(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.carter(17, relativeTo: .headline))
                    .foregroundStyle(Theme.orange)
            }
            ProgressBar(value: progress)
        }
        .padding(16)
        .frame(minHeight: 74)
        .background(Theme.panelRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
    }
}

func formatMoney(_ amount: Decimal, currency: BuildCurrency) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency.rawValue
    formatter.maximumFractionDigits = amount.doubleValue >= 1000 ? 0 : 2
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency.symbol)\(amount)"
}

func compactMoney(_ amount: Decimal, currency: BuildCurrency) -> String {
    let value = amount.doubleValue
    let symbol = currency.symbol
    if value >= 1_000_000 {
        return "\(symbol)\((value / 1_000_000).formatted(.number.precision(.fractionLength(1))))M"
    }
    if value >= 1_000 {
        return "\(symbol)\(Int(value / 1_000))k"
    }
    return formatMoney(amount, currency: currency)
}
