 import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct RoutineCreateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.themePalette) private var theme
    
    let routine: Routine?  // nil if creating new, non-nil if editing
    
    @State private var routineName: String = ""
    @State private var steps: [RoutineStepData] = []
    @State private var isTemplate: Bool = false
    @State private var savedTemplates: [Routine] = []
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var initialRoutineName: String = ""
    @State private var initialIsTemplate: Bool = false
    @State private var initialSteps: [RoutineStepData] = []
    
    @State private var draggingItem: RoutineStepData?
    
    let defaultTemplates = [
        RoutineTemplate(name: String(localized: "template.commute.name"), display: "30/10/20", steps: [
            RoutineStepData(name: String(localized: "template.commute.step.prepare"), duration: "3000"),
            RoutineStepData(name: String(localized: "template.commute.step.move"), duration: "1000"),
            RoutineStepData(name: String(localized: "template.commute.step.arrive"), duration: "2000")
        ]),
        RoutineTemplate(name: String(localized: "template.class.name"), display: "50/10/50/10", steps: [
            RoutineStepData(name: String(localized: "template.class.step.lesson1"), duration: "5000"),
            RoutineStepData(name: String(localized: "template.class.step.break"), duration: "1000"),
            RoutineStepData(name: String(localized: "template.class.step.lesson2"), duration: "5000"),
            RoutineStepData(name: String(localized: "template.class.step.cleanup"), duration: "1000")
        ])
    ]
    
    var isEditingMode: Bool {
        routine != nil
    }

    var isDirty: Bool {
        guard isEditingMode else { return true }
        return routineName != initialRoutineName
            || isTemplate != initialIsTemplate
            || steps != initialSteps
    }

    var isValid: Bool {
        guard !routineName.isEmpty else { return false }
        guard !steps.isEmpty else { return false }
        guard !steps.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return false }
        guard !steps.contains(where: { isZeroDuration($0.duration) }) else { return false }
        return true
    }

    var canSave: Bool {
        isValid && isDirty
    }
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 24) {
                            // Routine Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("routine.create.name.label")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, 4)
                                
                                TextField("routine.create.name.placeholder", text: $routineName)
                                    .font(.system(size: 17))
                                    .padding(16)
                                    .background(theme.surface)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.border, lineWidth: 1)
                                    )
                            }
                            
                            // Template Toggle
                            HStack {
                                Text("routine.create.template.toggle")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isTemplate)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                    .tint(theme.accent)
                            }
                            .padding(.top, -8) // Pull it closer to the field above
                            
                            // Templates Selection (Existing)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("routine.create.template.section")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // Default templates
                                        ForEach(defaultTemplates) { template in
                                            Button(action: {
                                                applyTemplate(template)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(template.name)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(theme.textPrimary)
                                                    Text("(\(template.display))")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(theme.textSecondary)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(theme.surface)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(theme.border, lineWidth: 1)
                                                )
                                            }
                                        }
                                        
                                        // Saved templates
                                        ForEach(savedTemplates) { routine in
                                            Button(action: {
                                                applyRoutineTemplate(routine)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(routine.name ?? String(localized: "app.routine.defaultName"))
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(theme.textPrimary)
                                                    Text("(\(getRoutineTimeDisplay(routine)))")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(theme.textSecondary)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(theme.surface)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(theme.border, lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.top, 24)
                        
                        // MARK: - Step List Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("routine.create.step.section")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 12) {
                                ForEach($steps) { $step in
                                    RoutineStepRow(step: $step, draggingItem: $draggingItem, onDelete: {
                                        if let index = steps.firstIndex(where: { $0.id == step.id }) {
                                            steps.remove(at: index)
                                        }
                                    })
                                    .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: step, listData: $steps, current: $draggingItem))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        
                        // Add Button Section
                        VStack(spacing: 8) {
                            if steps.isEmpty {
                                Text("routine.create.step.empty")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }
                            Button(action: {
                                addStep()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("routine.create.step.add")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.surface)
                                .cornerRadius(12)
                                .shadow(color: theme.shadow.opacity(0.4), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, 32)
                    }
                }
                
                // MARK: - Bottom Action Button
                VStack {
                    Button(action: {
                        saveRoutine()
                    }) {
                        Text("common.save")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave ? theme.accent : theme.accent.opacity(0.35))
                            .cornerRadius(AppRadius.standard)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.bottom, 10)
                }
                .padding(.top, 10)
                .background(theme.surface)
                .shadow(color: theme.shadow, radius: 8, y: -4)
            }
        }
        .navigationTitle(Text(isEditingMode ? "routine.create.title.edit" : "routine.create.title.new"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("routine.create.alert.title", isPresented: $showValidationAlert) {
            Button("common.confirm", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .onAppear {
            onAppear()
        }
    }
    
    // Logic
    private func applyTemplate(_ template: RoutineTemplate) {
        self.steps = template.steps
        self.routineName = template.name
    }
    
    private func getRoutineTimeDisplay(_ routine: Routine) -> String {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        return sortedSteps.map { formatCompactDuration(Int($0.durationSeconds)) }.joined(separator: "/")
    }
    
    private func applyRoutineTemplate(_ routine: Routine) {
        self.routineName = routine.name ?? String(localized: "app.routine.defaultName")
        let routineSteps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = routineSteps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        self.steps = sortedSteps.map { step in
            let storage = storageString(from: Int(step.durationSeconds))
            return RoutineStepData(name: step.title ?? String(localized: "app.step.defaultName"), duration: storage)
        }
    }
    
    private func addStep() {
        steps.append(RoutineStepData(name: "", duration: ""))
    }
    
    private func loadSavedTemplates() {
        savedTemplates = CoreDataManager.shared.fetchTemplateRoutines()
    }
    
    private func saveRoutine() {
        guard canSave else { return }
        guard !routineName.isEmpty else {
            showValidation(message: String(localized: "routine.create.validation.name"))
            return
        }
        guard !steps.isEmpty else {
            showValidation(message: String(localized: "routine.create.validation.steps"))
            return
        }
        guard !steps.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            showValidation(message: String(localized: "routine.create.validation.stepName"))
            return
        }
        guard !steps.contains(where: { isZeroDuration($0.duration) }) else {
            showValidation(message: String(localized: "routine.create.validation.duration"))
            return
        }
        
        let targetRoutine: Routine
        
        if let existingRoutine = routine {
            // 수정 모드: 기존 루틴 업데이트
            targetRoutine = existingRoutine
            targetRoutine.name = routineName
            targetRoutine.isTemplate = isTemplate
            targetRoutine.updatedAt = Date()
            
            // 기존 스텝 삭제
            if let existingSteps = targetRoutine.steps as? Set<RoutineStep> {
                for step in existingSteps {
                    managedObjectContext.delete(step)
                }
            }
            
            // 삭제 후 먼저 저장
            do {
                try managedObjectContext.save()
            } catch {
                print("Failed to save after deleting steps: \(error)")
            }
        } else {
            // 새로 생성 모드
            targetRoutine = CoreDataManager.shared.createRoutine(name: routineName)
            CoreDataManager.shared.updateRoutine(targetRoutine, isTemplate: isTemplate)
        }
        
        // 새로운 스텝 추가
        for (index, step) in steps.enumerated() {
            // duration은 숫자만 저장되어 있음 (예: "2500", "25000")
            // 마지막 2글자는 초, 나머지는 분
            let totalSeconds = totalSecondsFromStorage(step.duration)
            CoreDataManager.shared.createRoutineStep(
                routine: targetRoutine,
                order: Int16(index),
                title: step.name,
                durationSeconds: Int64(totalSeconds)
            )
        }
        
        // CoreData 저장
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to save routine: \(error)")
        }
        if let routineId = targetRoutine.routineId {
            let payloadHash = RoutinePayloadHasher.hash(for: targetRoutine)
            SyncManager.shared.enqueueRoutine(routineId: routineId, payloadHash: payloadHash)
        }
        dismiss()
    }

    private func isZeroDuration(_ duration: String) -> Bool {
        totalSecondsFromStorage(duration) == 0
    }

    private func showValidation(message: String) {
        validationMessage = message
        showValidationAlert = true
    }

    private func totalSecondsFromStorage(_ stored: String) -> Int {
        let digits = stored.filter { "0123456789".contains($0) }
        guard !digits.isEmpty else { return 0 }
        if digits.count <= 2 {
            return clampSecondsValue(Int(digits) ?? 0)
        }
        let minutesEndIndex = digits.index(digits.endIndex, offsetBy: -2)
        let minutes = Int(digits[..<minutesEndIndex]) ?? 0
        let seconds = clampSecondsValue(Int(digits[minutesEndIndex...]) ?? 0)
        return max(minutes * 60 + seconds, 0)
    }

    private func storageString(from totalSeconds: Int) -> String {
        let total = max(totalSeconds, 0)
        let totalMinutes = total / 60
        let seconds = total % 60
        return "\(totalMinutes)\(String(format: "%02d", seconds))"
    }

    private func formatCompactDuration(_ totalSeconds: Int) -> String {
        let total = max(totalSeconds, 0)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 && seconds > 0 {
            return String(format: String(localized: "duration.compact.ms"), minutes, seconds)
        }
        if minutes > 0 {
            return String(format: String(localized: "duration.compact.m"), minutes)
        }
        return String(format: String(localized: "duration.compact.s"), seconds)
    }

    private func clampSecondsValue(_ value: Int) -> Int {
        min(max(value, 0), 59)
    }
    
    func onAppear() {
        loadSavedTemplates()
        // 수정 모드일 경우 기존 데이터로 form 채우기
        if let routine = routine {
            routineName = routine.name ?? ""
            isTemplate = routine.isTemplate
            
            let routineSteps = routine.steps as? Set<RoutineStep> ?? []
            let sortedSteps = routineSteps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
            steps = sortedSteps.map { step in
                let storage = storageString(from: Int(step.durationSeconds))
                return RoutineStepData(name: step.title ?? String(localized: "app.step.defaultName"), duration: storage)
            }
        } else if steps.isEmpty {
            addStep()
        }
        captureInitialState()
    }

    private func captureInitialState() {
        initialRoutineName = routineName
        initialIsTemplate = isTemplate
        initialSteps = steps
    }
}

// MARK: - Drag & Drop Logic
struct DragRelocateDelegate: DropDelegate {
    let item: RoutineStepData
    @Binding var listData: [RoutineStepData]
    @Binding var current: RoutineStepData?

    func dropEntered(info: DropInfo) {
        guard let current = current else { return }
        guard item != current else { return }

        if let from = listData.firstIndex(of: current),
           let to = listData.firstIndex(of: item) {
            if listData[to] != current {
                withAnimation {
                    listData.move(fromOffsets: IndexSet(integer: from),
                                  toOffset: to > from ? to + 1 : to)
                }
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}

// MARK: - Models & Subviews

struct RoutineStepData: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var duration: String // Digits, "MMSS" where MM is total minutes and SS is seconds
}

struct RoutineTemplate: Identifiable {
    let id = UUID()
    let name: String
    let display: String
    let steps: [RoutineStepData]
}

struct RoutineStepRow: View {
    @Binding var step: RoutineStepData
    @Binding var draggingItem: RoutineStepData?
    var onDelete: () -> Void
    @Environment(\.themePalette) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            // Drag Handle (Left)
            Image(systemName: "line.3.horizontal")
                .foregroundColor(theme.textSecondary)
                .font(.system(size: 20))
                .padding(.trailing, 4)
                .onDrag {
                    self.draggingItem = step
                    return NSItemProvider(object: step.id.uuidString as NSString)
                }
            
            // Name Input
            TextField("routine.create.stepName.placeholder", text: $step.name)
                .font(.system(size: 16))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(theme.background)
                .cornerRadius(8)
                .frame(minWidth: 100, maxWidth: .infinity)
                .layoutPriority(1)
            
            // Time Input (Button + Bottom Sheet)
            TimePickerButton(duration: $step.duration)
                .frame(width: 120)
                .background(theme.background)
                .cornerRadius(6)
            
            // Delete Icon
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 4))
        .background(theme.surface)
        .cornerRadius(12)
        .shadow(color: theme.shadow.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

struct TimePickerButton: View {
    @Binding var duration: String
    @State private var isSheetPresented = false
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @Environment(\.themePalette) private var theme

    var body: some View {
        Button(action: {
            syncPickerFromStorage()
            isSheetPresented = true
        }) {
            HStack(spacing: 6) {
                Text(formatDisplayFromStorage(duration))
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isSheetPresented) {
            TimePickerSheet(
                hours: $hours,
                minutes: $minutes,
                seconds: $seconds,
                onDone: {
                    applyPickerToStorage()
                    isSheetPresented = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
    }

    private func syncPickerFromStorage() {
        let parsed = parseStorage(duration)
        let totalMinutes = parsed.totalMinutes
        hours = totalMinutes / 60
        minutes = totalMinutes % 60
        seconds = parsed.seconds
    }

    private func applyPickerToStorage() {
        let totalMinutes = hours * 60 + minutes
        duration = "\(totalMinutes)\(String(format: "%02d", seconds))"
    }

    private func formatDisplayFromStorage(_ stored: String) -> String {
        let parsed = parseStorage(stored)
        let totalMinutes = parsed.totalMinutes
        let displayHours = totalMinutes / 60
        let displayMinutes = totalMinutes % 60
        return String(format: "%02d:%02d:%02d", displayHours, displayMinutes, parsed.seconds)
    }

    private func parseStorage(_ stored: String) -> (totalMinutes: Int, seconds: Int) {
        let digits = stored.filter { "0123456789".contains($0) }
        guard !digits.isEmpty else { return (0, 0) }
        if digits.count <= 2 {
            return (0, clampSecondsValue(Int(digits) ?? 0))
        }
        let minutesEndIndex = digits.index(digits.endIndex, offsetBy: -2)
        let minutes = Int(digits[..<minutesEndIndex]) ?? 0
        let seconds = clampSecondsValue(Int(digits[minutesEndIndex...]) ?? 0)
        return (minutes, seconds)
    }

    private func clampSecondsValue(_ value: Int) -> Int {
        min(max(value, 0), 59)
    }
}

struct TimePickerSheet: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    var onDone: () -> Void
    @Environment(\.themePalette) private var theme

    private let hourRange = Array(0...99)
    private let minuteSecondRange = Array(0...59)

    var body: some View {
        VStack(spacing: 0) {
            Text("routine.create.time.title")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                Picker("routine.create.time.hours", selection: $hours) {
                    ForEach(hourRange, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("routine.create.time.minutes", selection: $minutes) {
                    ForEach(minuteSecondRange, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("routine.create.time.seconds", selection: $seconds) {
                    ForEach(minuteSecondRange, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .padding(.horizontal, 8)
            HStack {
                Text("routine.create.time.hours")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                Text("routine.create.time.minutes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                Text("routine.create.time.seconds")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, -8)

            Button(action: onDone) {
                Text("common.done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.accent)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    NavigationStack {
        RoutineCreateView(routine: nil)
    }
}
