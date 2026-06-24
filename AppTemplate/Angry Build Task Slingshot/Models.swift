import Foundation

struct BuildProject: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var address: String
    var clientName: String
    var clientPhone: String
    var startDate: Date
    var deadline: Date
    var plannedBudget: Decimal
    var currency: BuildCurrency
    var notes: String
    var isArchived = false
    var createdAt = Date()
}

enum BuildCurrency: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case aud = "AUD"
    case gbp = "GBP"
    case cad = "CAD"
    case eur = "EUR"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .usd, .aud, .cad: "$"
        case .gbp: "£"
        case .eur: "€"
        }
    }
}

struct BuildTaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectID: UUID
    var title: String
    var details: String
    var priority: TaskPriority
    var assignee: String
    var deadline: Date
    var status: BuildTaskStatus
    var checklist: [TaskChecklistItem]
    var materials: [MaterialItem]
    var attachments: [AttachmentReference]
    var createdAt = Date()
    var completedAt: Date?
}

enum BuildTaskStatus: String, CaseIterable, Identifiable, Codable {
    case todo
    case inProgress
    case done

    var id: String { rawValue }
    var title: String {
        switch self {
        case .todo: "TO DO"
        case .inProgress: "IN PROGRESS"
        case .done: "DONE"
        }
    }
}

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }
}

struct TaskChecklistItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
}

struct MaterialItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var quantity: String
    var unit: String
    var estimatedCost: Decimal
}

struct ExpenseItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectID: UUID
    var taskID: UUID?
    var category: ExpenseCategory
    var name: String
    var amount: Decimal
    var supplier: String
    var date: Date
    var receipt: AttachmentReference?
    var createdAt = Date()
}

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case materials = "Materials"
    case labor = "Labor"
    case delivery = "Delivery"
    case equipment = "Equipment"
    case other = "Other"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .materials: "shippingbox.fill"
        case .labor: "person.crop.circle.badge.checkmark"
        case .delivery: "truck.box.fill"
        case .equipment: "wrench.and.screwdriver.fill"
        case .other: "tray.fill"
        }
    }
}

struct AttachmentReference: Identifiable, Codable, Equatable {
    var id = UUID()
    var originalName: String
    var storedFileName: String
    var kind: AttachmentKind
    var addedAt = Date()
}

enum AttachmentKind: String, Codable {
    case photo
    case pdf
}

struct BuildSnapshot: Codable, Equatable {
    var projects: [BuildProject] = []
    var tasks: [BuildTaskItem] = []
    var expenses: [ExpenseItem] = []
    var selectedProjectID: UUID?
}
