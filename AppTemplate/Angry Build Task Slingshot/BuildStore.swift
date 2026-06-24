import Foundation
import Combine
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class BuildStore: ObservableObject {
    @Published private(set) var projects: [BuildProject] = []
    @Published private(set) var tasks: [BuildTaskItem] = []
    @Published private(set) var expenses: [ExpenseItem] = []
    @Published var selectedProjectID: UUID?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    private let repository: BuildRepository

    init(repository: BuildRepository) {
        self.repository = repository
    }

    var selectedProject: BuildProject? {
        if let selectedProjectID, let project = projects.first(where: { $0.id == selectedProjectID }) {
            return project
        }
        return projects.first
    }

    var selectedProjectTasks: [BuildTaskItem] {
        guard let projectID = selectedProject?.id else { return [] }
        return tasks.filter { $0.projectID == projectID }
    }

    var selectedProjectExpenses: [ExpenseItem] {
        guard let projectID = selectedProject?.id else { return [] }
        return expenses.filter { $0.projectID == projectID }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await repository.load()
            projects = snapshot.projects
            tasks = snapshot.tasks
            expenses = snapshot.expenses
            selectedProjectID = snapshot.selectedProjectID ?? projects.first?.id
        } catch {
            errorMessage = "Build data could not be loaded. You can keep using the app, but new changes may not restore until storage is available."
        }
    }

    func saveProject(_ project: BuildProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.insert(project, at: 0)
            selectedProjectID = project.id
        }
        persist(success: "Project saved")
    }

    func saveTask(_ task: BuildTaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }
        persist(success: "Task saved")
    }

    func saveExpense(_ expense: ExpenseItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        } else {
            expenses.insert(expense, at: 0)
        }
        persist(success: "Expense saved")
    }

    func moveTask(_ task: BuildTaskItem, to status: BuildTaskStatus) {
        if status == .done {
            completeTask(task)
            return
        }
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
        tasks[index].completedAt = nil
        persist(success: "Task moved")
    }

    func launchTask(_ task: BuildTaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard tasks[index].status == .todo else {
            toastMessage = "Slingshot Launch is available only from To Do"
            clearToastSoon()
            return
        }
        if isChecklistComplete(tasks[index]) {
            tasks[index].status = .done
            tasks[index].completedAt = Date()
            persist(success: "Task launched to Done")
        } else {
            tasks[index].status = .inProgress
            tasks[index].completedAt = nil
            persist(success: "Task launched to In Progress")
        }
    }

    func toggleChecklist(taskID: UUID, itemID: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskID }),
              let itemIndex = tasks[taskIndex].checklist.firstIndex(where: { $0.id == itemID }) else { return }
        tasks[taskIndex].checklist[itemIndex].isDone.toggle()
        if tasks[taskIndex].status != .todo {
            syncActiveTaskStatus(at: taskIndex)
        }
        persist(success: nil)
    }

    func selectProject(_ project: BuildProject) {
        selectedProjectID = project.id
        persist(success: nil)
    }

    func copyPhotoItem(_ item: PhotosPickerItem) async throws -> AttachmentReference {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw BuildStorageError.unreadableAttachment
        }
        return try await repository.saveAttachment(data: data, preferredName: "photo.jpg", kind: .photo)
    }

    func copyImportedFile(from url: URL, kind: AttachmentKind) async throws -> AttachmentReference {
        try await repository.saveAttachment(from: url, kind: kind)
    }

    func clearToastSoon() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            toastMessage = nil
        }
    }

    private func persist(success: String?) {
        let snapshot = BuildSnapshot(projects: projects, tasks: tasks, expenses: expenses, selectedProjectID: selectedProjectID)
        Task {
            do {
                try await repository.save(snapshot)
                if let success {
                    toastMessage = success
                    clearToastSoon()
                }
            } catch {
                errorMessage = "Changes could not be saved. Check available storage and try again."
            }
        }
    }

    private func completeTask(_ task: BuildTaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard isChecklistComplete(tasks[index]) else {
            tasks[index].status = .inProgress
            tasks[index].completedAt = nil
            persist(success: "Task moved to In Progress until the checklist is complete")
            return
        }
        tasks[index].status = .done
        tasks[index].completedAt = Date()
        persist(success: "Task completed")
    }

    private func syncActiveTaskStatus(at index: Int) {
        if isChecklistComplete(tasks[index]) {
            tasks[index].status = .done
            tasks[index].completedAt = tasks[index].completedAt ?? Date()
        } else {
            tasks[index].status = .inProgress
            tasks[index].completedAt = nil
        }
    }

    private func isChecklistComplete(_ task: BuildTaskItem) -> Bool {
        task.checklist.allSatisfy(\.isDone)
    }
}

protocol BuildRepository {
    func load() async throws -> BuildSnapshot
    func save(_ snapshot: BuildSnapshot) async throws
    func saveAttachment(data: Data, preferredName: String, kind: AttachmentKind) async throws -> AttachmentReference
    func saveAttachment(from url: URL, kind: AttachmentKind) async throws -> AttachmentReference
}

enum BuildStorageError: Error {
    case unreadableAttachment
}

struct LocalBuildRepository: BuildRepository {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async throws -> BuildSnapshot {
        let url = try dataURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return BuildSnapshot()
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(BuildSnapshot.self, from: data)
    }

    func save(_ snapshot: BuildSnapshot) async throws {
        let url = try dataURL()
        try ensureSupportDirectory()
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }

    func saveAttachment(data: Data, preferredName: String, kind: AttachmentKind) async throws -> AttachmentReference {
        try ensureSupportDirectory()
        let ext = (preferredName as NSString).pathExtension.isEmpty ? (kind == .pdf ? "pdf" : "jpg") : (preferredName as NSString).pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        let destination = try attachmentsDirectory().appendingPathComponent(fileName)
        try data.write(to: destination, options: [.atomic])
        return AttachmentReference(originalName: preferredName, storedFileName: fileName, kind: kind)
    }

    func saveAttachment(from url: URL, kind: AttachmentKind) async throws -> AttachmentReference {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        try ensureSupportDirectory()
        let ext = url.pathExtension.isEmpty ? (kind == .pdf ? "pdf" : "dat") : url.pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        let destination = try attachmentsDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return AttachmentReference(originalName: url.lastPathComponent, storedFileName: fileName, kind: kind)
    }

    private func dataURL() throws -> URL {
        try supportDirectory().appendingPathComponent("build-data.json")
    }

    private func supportDirectory() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("AngryBuild", isDirectory: true)
    }

    private func attachmentsDirectory() throws -> URL {
        try supportDirectory().appendingPathComponent("Attachments", isDirectory: true)
    }

    private func ensureSupportDirectory() throws {
        try FileManager.default.createDirectory(at: supportDirectory(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: attachmentsDirectory(), withIntermediateDirectories: true)
    }
}
