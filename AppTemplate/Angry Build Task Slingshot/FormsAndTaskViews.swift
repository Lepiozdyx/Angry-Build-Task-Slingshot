import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProjectFormView: View {
    @EnvironmentObject private var store: BuildStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var startDate = Date()
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
    @State private var budget = ""
    @State private var currency: BuildCurrency = .usd
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    formHeader

                    projectTextField("PROJECT NAME", placeholder: "e.g. Downtown Office Renovation", text: $name, required: true)
                    projectTextField("ADDRESS", placeholder: "e.g. 123 Main St, New York, NY", text: $address)
                    projectTextField("CLIENT NAME", placeholder: "e.g. Acme Corporation", text: $clientName)
                    projectTextField("CLIENT PHONE", placeholder: "+1 (555) 000-0000", text: $clientPhone)
                        .keyboardType(.phonePad)
                    dateField("START DATE", date: $startDate)
                    dateField("DEADLINE", date: $deadline)
                    projectTextField("PLANNED BUDGET", placeholder: "100000", text: $budget, required: true)
                        .keyboardType(.decimalPad)
                    currencyField
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(title: "Description")
                        TextEditor(text: $notes)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .frame(minHeight: 90)
                            .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
                            .overlay(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Project overview, scope notes...")
                                        .foregroundStyle(Theme.mutedText)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.top, 2)
                    }

                    Button {
                        save()
                    } label: {
                        Label("Create Project", systemImage: "building.2.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 22)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .keyboardToolbar()
    }

    private var formHeader: some View {
        HStack(alignment: .center) {
            RoundIconButton(systemName: "arrow.left") {
                dismiss()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("New Project")
                    .font(.brandTitle)
                Text("Create construction object")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer()
            Text("+ New")
                .font(.carter(13, relativeTo: .caption))
                .foregroundStyle(Theme.orange.opacity(0.18))
                .padding(.horizontal, 13)
                .frame(height: 38)
                .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.bottom, 7)
    }

    private func projectTextField(_ label: String, placeholder: String, text: Binding<String>, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: label, isRequired: required)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
        }
    }

    private func dateField(_ label: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: label)
            HStack {
                Text(date.wrappedValue.formatted(date: .numeric, time: .omitted))
                    .foregroundStyle(Theme.mutedText)
                Spacer()
                DatePicker(label, selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.orange)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
        }
    }

    private var currencyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "Currency")
            Menu {
                ForEach(BuildCurrency.allCases) { item in
                    Button(item.rawValue) {
                        currency = item
                    }
                }
            } label: {
                HStack {
                    Text(currency.rawValue)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.mutedText)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Project name is required."
            return
        }
        guard let amount = Decimal(string: budget.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            validationMessage = "Enter a planned budget greater than zero."
            return
        }
        guard deadline >= startDate else {
            validationMessage = "Deadline must be on or after the start date."
            return
        }
        store.saveProject(BuildProject(name: trimmedName, address: address, clientName: clientName, clientPhone: clientPhone, startDate: startDate, deadline: deadline, plannedBudget: amount, currency: currency, notes: notes))
        dismiss()
    }
}

struct TaskFormView: View {
    @EnvironmentObject private var store: BuildStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var priority: TaskPriority = .medium
    @State private var assignee = "Foreman"
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var checklistText = ""
    @State private var checklist: [TaskChecklistItem] = []
    @State private var materialName = ""
    @State private var materialCost = ""
    @State private var materials: [MaterialItem] = []
    @State private var attachments: [AttachmentReference] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isImportingPDF = false
    @State private var validationMessage: String?
    @State private var attachmentMessage: String?

    private let assignees = ["Foreman", "Electrician", "Plumber", "Designer", "Client"]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    taskFormHeader
                    taskTextField("TASK NAME", placeholder: "e.g. Install HVAC Ducting", text: $title, required: true)
                    taskEditor
                    prioritySelector
                    assigneePicker
                    deadlineFields
                    checklistSection
                    materialsSection
                    photosSection
                    pdfSection

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    if let attachmentMessage {
                        Text(attachmentMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }

                    Button {
                        save()
                    } label: {
                        Label("Create Task", systemImage: "hammer.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .keyboardToolbar()
        .onChange(of: selectedPhotos) { _, items in
            copyPhotos(items)
        }
        .fileImporter(isPresented: $isImportingPDF, allowedContentTypes: [.pdf]) { result in
            copyPDF(result)
        }
    }

    private var taskFormHeader: some View {
        HStack(spacing: 12) {
            RoundIconButton(systemName: "xmark") {
                dismiss()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("CONSTRUCTION BOARD")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                Text("Create Task")
                    .font(.brandTitle)
            }
            Spacer()
            TopActionButton(title: "Save") {
                save()
            }
        }
        .padding(.bottom, 2)
    }

    private func taskTextField(_ label: String, placeholder: String, text: Binding<String>, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: label, isRequired: required)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
        }
    }

    private var taskEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "WORK DESCRIPTION")
            TextEditor(text: $details)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(minHeight: 116)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
                .overlay(alignment: .topLeading) {
                    if details.isEmpty {
                        Text("Describe the scope of work, notes, special instructions...")
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var prioritySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "PRIORITY")
            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases) { item in
                    Button {
                        priority = item
                    } label: {
                        Text(item.rawValue)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(priority == item ? priorityTint(item) : Theme.mutedText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(priority == item ? priorityTint(item).opacity(0.16) : Color.white.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(priority == item ? priorityTint(item).opacity(0.65) : Color.white.opacity(0.08)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var assigneePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "ASSIGNEE")
            Menu {
                ForEach(assignees, id: \.self) { member in
                    Button(member) {
                        assignee = member
                    }
                }
            } label: {
                HStack {
                    Text(assignee.isEmpty ? "Select team member" : assignee)
                        .foregroundStyle(assignee.isEmpty ? Theme.mutedText : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
            }
        }
    }

    private var deadlineFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "DEADLINE")
            HStack(spacing: 8) {
                HStack {
                    Text(deadline.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(Theme.mutedText)
                        .lineLimit(1)
                    Spacer()
                    DatePicker("Deadline date", selection: $deadline, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Theme.orange)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))

                HStack {
                    DatePicker("Deadline time", selection: $deadline, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Theme.orange)
                    Image(systemName: "clock")
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, 10)
                .frame(width: 112, height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DividerTitle(icon: "checkmark.square.fill", title: "Checklist", tint: Theme.green)
            HStack(spacing: 8) {
                TextField("Add checklist item...", text: $checklistText)
                    .textInputAutocapitalization(.sentences)
                Button("Add") {
                    addChecklistItem()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(checklistText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.mutedText : Theme.orange)
                .disabled(checklistText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Theme.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.65)))

            ForEach(checklist) { item in
                Label(item.title, systemImage: "circle")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
        }
    }

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DividerTitle(icon: "shippingbox.fill", title: "Materials", tint: Theme.orange)
            HStack(spacing: 8) {
                TextField("Material name", text: $materialName)
                    .textInputAutocapitalization(.words)
                TextField("Cost", text: $materialCost)
                    .keyboardType(.decimalPad)
                    .frame(width: 78)
                Button {
                    addMaterial()
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(materialName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.yellow.opacity(0.25)))

            ForEach(materials) { material in
                HStack {
                    Text(material.name)
                    Spacer()
                    Text("$\(material.estimatedCost)")
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.yellow)
                }
                .font(.caption)
                .foregroundStyle(.white)
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DividerTitle(icon: "photo.on.rectangle", title: "Before / After Photos", tint: Theme.mutedText)
            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images) {
                    AttachmentTile(icon: "camera.fill", title: "+ Before Photo", tint: Theme.orange)
                }
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images) {
                    AttachmentTile(icon: "photo", title: "+ After Photo", tint: Theme.green)
                }
            }
            if !attachments.filter({ $0.kind == .photo }).isEmpty {
                Text("\(attachments.filter { $0.kind == .photo }.count) photos attached")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
        }
    }

    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DividerTitle(icon: "paperclip", title: "PDF Attachments", tint: Theme.mutedText)
            Button {
                isImportingPDF = true
            } label: {
                HStack {
                    Image(systemName: "paperclip")
                    Text(attachments.filter { $0.kind == .pdf }.isEmpty ? "Attach PDF" : "\(attachments.filter { $0.kind == .pdf }.count) PDF attached")
                    Spacer()
                    Image(systemName: "plus")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.orange)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.6)))
            }
            .buttonStyle(.plain)
        }
    }

    private func priorityTint(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: .gray
        case .medium: Theme.yellow
        case .high: Theme.orange
        case .critical: .red
        }
    }

    private func addChecklistItem() {
        let text = checklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        checklist.append(TaskChecklistItem(title: text))
        checklistText = ""
    }

    private func addMaterial() {
        let text = materialName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let cost = Decimal(string: materialCost.replacingOccurrences(of: ",", with: ".")), cost >= 0 else {
            attachmentMessage = "Enter material name and a valid cost."
            return
        }
        materials.append(MaterialItem(name: text, quantity: "1", unit: "item", estimatedCost: cost))
        materialName = ""
        materialCost = ""
        attachmentMessage = nil
    }

    private func copyPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                do {
                    let attachment = try await store.copyPhotoItem(item)
                    attachments.append(attachment)
                    attachmentMessage = nil
                } catch {
                    attachmentMessage = "A photo could not be copied. Try selecting it again."
                }
            }
            selectedPhotos = []
        }
    }

    private func copyPDF(_ result: Result<URL, Error>) {
        Task {
            do {
                let url = try result.get()
                let attachment = try await store.copyImportedFile(from: url, kind: .pdf)
                attachments.append(attachment)
                attachmentMessage = nil
            } catch {
                attachmentMessage = "The PDF could not be attached. Try another file."
            }
        }
    }

    private func save() {
        guard let projectID = store.selectedProject?.id else {
            validationMessage = "Create or select a project before adding tasks."
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Task name is required."
            return
        }
        store.saveTask(BuildTaskItem(projectID: projectID, title: trimmedTitle, details: details, priority: priority, assignee: assignee, deadline: deadline, status: .todo, checklist: checklist, materials: materials, attachments: attachments))
        dismiss()
    }
}

struct DividerTitle: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
}

struct AttachmentTile: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35)))
    }
}

struct ExpenseFormView: View {
    @EnvironmentObject private var store: BuildStore
    @Environment(\.dismiss) private var dismiss
    @State private var category: ExpenseCategory = .materials
    @State private var name = ""
    @State private var amount = ""
    @State private var supplier = ""
    @State private var date = Date()
    @State private var selectedTaskID: UUID?
    @State private var selectedReceipt: PhotosPickerItem?
    @State private var receipt: AttachmentReference?
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    expenseHeader
                    categorySelector
                    expenseTextField("EXPENSE NAME", placeholder: "e.g. Concrete Delivery", text: $name)
                    expenseTextField("AMOUNT ($)", placeholder: "0.00", text: $amount)
                        .keyboardType(.decimalPad)
                    expenseTextField("SUPPLIER", placeholder: "e.g. Ready Mix Pro", text: $supplier)
                    dateField

                    Spacer(minLength: 64)

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }

                    Button {
                        save()
                    } label: {
                        Text("Save Expense")
                    }
                    .buttonStyle(BudgetPrimaryButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .keyboardToolbar()
        .onChange(of: selectedReceipt) { _, item in
            guard let item else { return }
            Task {
                do {
                    receipt = try await store.copyPhotoItem(item)
                    validationMessage = nil
                } catch {
                    validationMessage = "Receipt photo could not be copied. Try again."
                }
                selectedReceipt = nil
            }
        }
    }

    private var expenseHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundIconButton(systemName: "arrow.left") {
                dismiss()
            }
            Text("Add Expense")
                .font(.brandTitle)
            Spacer()
            Text("+ Expense")
                .font(.carter(13, relativeTo: .caption))
                .foregroundStyle(Theme.yellow.opacity(0.16))
                .padding(.horizontal, 13)
                .frame(height: 38)
                .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "CATEGORY")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(ExpenseCategory.allCases) { item in
                    Button {
                        category = item
                    } label: {
                        Label(item.rawValue, systemImage: item.symbol)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(category == item ? Theme.orange : Theme.mutedText)
                            .padding(.horizontal, 10)
                            .frame(height: 31)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(category == item ? Theme.orange.opacity(0.17) : Color.white.opacity(0.07))
                                    .overlay(Capsule().stroke(category == item ? Theme.border : Color.clear))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func expenseTextField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: label)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "DATE")
            HStack {
                Text(date.formatted(date: .numeric, time: .omitted))
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
                Spacer()
                DatePicker("Expense date", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.yellow)
            }
            .padding(.horizontal, 12)
            .frame(height: 54)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
        }
    }

    private var linkedTaskField: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "LINKED TASK")
            Menu {
                Button("No task") {
                    selectedTaskID = nil
                }
                ForEach(store.selectedProjectTasks) { task in
                    Button(task.title) {
                        selectedTaskID = task.id
                    }
                }
            } label: {
                HStack {
                    Text(selectedTaskTitle)
                        .foregroundStyle(selectedTaskID == nil ? Theme.mutedText : .white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08)))
            }
        }
    }

    private var receiptPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "RECEIPT")
            PhotosPicker(selection: $selectedReceipt, matching: .images) {
                HStack {
                    Image(systemName: receipt == nil ? "receipt" : "checkmark.circle.fill")
                    Text(receipt == nil ? "Add Receipt Photo" : "Receipt Attached")
                    Spacer()
                    Image(systemName: "photo")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(receipt == nil ? Theme.yellow : Theme.green)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke((receipt == nil ? Theme.yellow : Theme.green).opacity(0.35)))
            }
        }
    }

    private var selectedTaskTitle: String {
        guard let selectedTaskID,
              let task = store.selectedProjectTasks.first(where: { $0.id == selectedTaskID }) else {
            return "No linked task"
        }
        return task.title
    }

    private func save() {
        guard let projectID = store.selectedProject?.id else {
            validationMessage = "Create or select a project before adding expenses."
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Expense name is required."
            return
        }
        guard let parsedAmount = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")), parsedAmount > 0 else {
            validationMessage = "Enter an amount greater than zero."
            return
        }
        store.saveExpense(ExpenseItem(projectID: projectID, taskID: selectedTaskID, category: category, name: trimmedName, amount: parsedAmount, supplier: supplier, date: date, receipt: receipt))
        dismiss()
    }
}

struct BudgetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.yellow)
                    .shadow(color: Theme.yellow.opacity(configuration.isPressed ? 0.18 : 0.42), radius: 18, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Animation.easeInOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct TaskColumn: View {
    @EnvironmentObject private var store: BuildStore
    let status: BuildTaskStatus
    let tasks: [BuildTaskItem]
    let onAddTask: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            columnHeader
            if tasks.isEmpty {
                emptyColumn
            } else {
                ForEach(tasks) { task in
                    NavigationLink {
                        TaskDetailView(taskID: task.id)
                    } label: {
                        TaskCard(task: task, tint: tint)
                    }
                    .buttonStyle(.plain)
                }
            }
            if status == .todo {
                Button {
                    onAddTask()
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Label(status.title, systemImage: icon)
                .font(.carter(15, relativeTo: .headline))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 6)
            if status == .todo {
                Button {
                    onAddTask()
                } label: {
                    Text("+ Add")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.orange)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Theme.orange.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(Theme.border))
                }
                .buttonStyle(.plain)
            }
            Text("\(tasks.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(minWidth: 28, minHeight: 28)
                .background(countBackground, in: Capsule())
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(headerBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.28)))
    }

    private var emptyColumn: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title3)
            Text(emptyText)
                .multilineTextAlignment(.center)
                .font(.caption)
        }
        .foregroundStyle(Theme.mutedText)
        .frame(maxWidth: .infinity, minHeight: 118)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.16)))
    }

    private var headerBackground: Color {
        switch status {
        case .todo: Theme.panelRaised.opacity(0.94)
        case .inProgress: Theme.blue.opacity(0.18)
        case .done: Theme.green.opacity(0.2)
        }
    }

    private var countBackground: Color {
        switch status {
        case .todo: Theme.orange
        case .inProgress: Theme.blue
        case .done: Theme.green
        }
    }

    private var tint: Color {
        switch status {
        case .todo: Theme.orange
        case .inProgress: Theme.blue
        case .done: Theme.green
        }
    }

    private var icon: String {
        switch status {
        case .todo: "clipboard"
        case .inProgress: "hammer.fill"
        case .done: "checkmark.square.fill"
        }
    }

    private var emptyText: String {
        switch status {
        case .todo: "Add planned work here."
        case .inProgress: "Move active tasks here."
        case .done: "Completed work lands here."
        }
    }
}

struct TaskCard: View {
    @EnvironmentObject private var store: BuildStore
    let task: BuildTaskItem
    let tint: Color
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 8) {
                Text(task.priority.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(priorityColor.opacity(0.16), in: Capsule())
                    .overlay(Capsule().stroke(priorityColor.opacity(0.35)))
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                Spacer()
            }

            Label(task.deadline.formatted(date: .numeric, time: .omitted), systemImage: task.deadline < Date() && task.status != .done ? "calendar.badge.exclamationmark" : "calendar")
                .font(.caption)
                .foregroundStyle(task.deadline < Date() && task.status != .done ? .red : Theme.mutedText)

            if !task.checklist.isEmpty {
                HStack {
                    Text("Checklist")
                    Spacer()
                    Text("\(completedChecklist)/\(task.checklist.count)")
                }
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
                ProgressBar(value: Double(completedChecklist) / Double(task.checklist.count), tint: tint)
            }

            HStack(spacing: 8) {
                Label("\(task.attachments.filter { $0.kind == .photo }.count)", systemImage: "photo")
                Label("\(task.attachments.filter { $0.kind == .pdf }.count)", systemImage: "paperclip")
                Spacer()
                Label(task.assignee, systemImage: "person.fill")
                    .lineLimit(1)
            }
            .font(.caption2)
            .foregroundStyle(Theme.mutedText)

            if canLaunch {
                Button {
                    store.launchTask(task)
                } label: {
                    Label("SLINGSHOT LAUNCH", systemImage: "target")
                        .font(.carter(12, relativeTo: .caption))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BoardLaunchButtonStyle())
                .padding(.horizontal, -14)
                .padding(.bottom, -14)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(minHeight: canLaunch ? 178 : 140, alignment: .top)
        .background(Theme.panelRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(priorityColor.opacity(0.26)))
        .offset(y: canLaunch ? min(max(dragOffset.height, 0), 70) : 0)
        .rotationEffect(.degrees(canLaunch ? Double(dragOffset.height / 18) : 0))
        .gesture(
            DragGesture(minimumDistance: 12)
                .updating($dragOffset) { value, state, _ in
                    if canLaunch {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    if canLaunch, value.translation.height > 70 {
                        store.launchTask(task)
                    }
                }
        )
    }

    private var completedChecklist: Int {
        task.checklist.filter { $0.isDone }.count
    }

    private var canLaunch: Bool {
        task.status == .todo
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: .gray
        case .medium: Theme.yellow
        case .high: Theme.orange
        case .critical: .red
        }
    }
}

struct TaskDetailView: View {
    @EnvironmentObject private var store: BuildStore
    @Environment(\.dismiss) private var dismiss
    let taskID: UUID

    private var task: BuildTaskItem? {
        store.tasks.first { $0.id == taskID }
    }

    var body: some View {
        ZStack {
            AppBackground()
            if let task {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailHeader(task)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .font(.brandTitle)
                            Text(task.details.isEmpty ? "No description added yet." : task.details)
                                .foregroundStyle(Theme.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            DetailInfoCard(title: "Assignee", value: task.assignee)
                            DetailInfoCard(title: "Deadline", value: task.deadline.formatted(date: .numeric, time: .omitted))
                            DetailInfoCard(title: "Photos", value: "\(task.attachments.filter { $0.kind == .photo }.count) attached")
                            DetailInfoCard(title: "Attachments", value: "\(task.attachments.filter { $0.kind == .pdf }.count) files")
                        }
                        if !task.checklist.isEmpty {
                            sectionTitle("CHECKLIST", trailing: "\(task.checklist.filter { $0.isDone }.count)/\(task.checklist.count)")
                            ForEach(task.checklist) { item in
                                Button {
                                    store.toggleChecklist(taskID: task.id, itemID: item.id)
                                } label: {
                                    HStack {
                                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(item.isDone ? Theme.green : Theme.mutedText)
                                        Text(item.title)
                                            .strikethrough(item.isDone)
                                        Spacer()
                                    }
                                    .foregroundStyle(item.isDone ? Theme.mutedText : .white)
                                    .padding(12)
                                    .frame(minHeight: 36)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !task.materials.isEmpty {
                            sectionTitle("MATERIALS")
                            ForEach(task.materials) { material in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(material.name)
                                        Text("\(material.quantity) \(material.unit)")
                                            .font(.caption)
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                    Spacer()
                                    Text("$\(material.estimatedCost)")
                                        .foregroundStyle(Theme.yellow)
                                        .fontWeight(.bold)
                                }
                                .padding(12)
                                .frame(minHeight: 52)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        sectionTitle("MOVE TO")
                        HStack(spacing: 8) {
                            statusButton(.inProgress, task: task)
                            statusButton(.done, task: task)
                        }
                    }
                    .padding(16)
                }
            } else {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "Task not found", message: "This task is no longer available.", actionTitle: nil, action: nil)
                    .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func detailHeader(_ task: BuildTaskItem) -> some View {
        HStack {
            RoundIconButton(systemName: "arrow.left") {
                dismiss()
            }
            Text("Task Details")
                .font(.brandTitle)
            Spacer()
            Text(task.priority.rawValue)
                .font(.caption.weight(.bold))
                .foregroundStyle(priorityColor(task.priority))
                .padding(.horizontal, 10)
                .frame(height: 25)
                .background(priorityColor(task.priority).opacity(0.18), in: Capsule())
        }
    }

    private func sectionTitle(_ title: String, trailing: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.mutedText)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.yellow)
            }
        }
    }

    private func statusButton(_ status: BuildTaskStatus, task: BuildTaskItem) -> some View {
        Button {
            store.moveTask(task, to: status)
        } label: {
            Label(status == .done ? "DONE" : status.title, systemImage: status == .done ? "checkmark" : "hammer.fill")
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
        }
        .disabled(task.status == status)
        .foregroundStyle(status == .done ? Theme.green : Theme.blue)
        .background((status == .done ? Theme.green : Theme.blue).opacity(task.status == status ? 0.08 : 0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke((status == .done ? Theme.green : Theme.blue).opacity(0.45)))
        .buttonStyle(.plain)
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: .gray
        case .medium: Theme.yellow
        case .high: Theme.orange
        case .critical: .red
        }
    }
}

struct DetailInfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        .background(Theme.field.opacity(0.86), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct BoardLaunchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.orange)
            .frame(height: 44)
            .background(Theme.orange.opacity(configuration.isPressed ? 0.13 : 0.08))
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.border.opacity(0.55)).frame(height: 0.6)
            }
    }
}
