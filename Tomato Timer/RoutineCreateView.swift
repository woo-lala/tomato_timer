 import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct RoutineCreateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    let routine: Routine?  // nil if creating new, non-nil if editing
    
    @State private var routineName: String = ""
    @State private var steps: [RoutineStepData] = []
    @State private var isTemplate: Bool = false
    @State private var savedTemplates: [Routine] = []
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    
    @State private var draggingItem: RoutineStepData?
    
    let defaultTemplates = [
        RoutineTemplate(name: "출근 루틴", display: "30/10/20", steps: [
            RoutineStepData(name: "준비", duration: "3000"),
            RoutineStepData(name: "이동", duration: "1000"),
            RoutineStepData(name: "도착", duration: "2000")
        ]),
        RoutineTemplate(name: "수업 루틴", display: "50/10/50/10", steps: [
            RoutineStepData(name: "수업 1", duration: "5000"),
            RoutineStepData(name: "쉬는시간", duration: "1000"),
            RoutineStepData(name: "수업 2", duration: "5000"),
            RoutineStepData(name: "정리", duration: "1000")
        ])
    ]
    
    var isEditingMode: Bool {
        routine != nil
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 24) {
                            // Routine Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("루틴 이름")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                TextField("새 루틴", text: $routineName)
                                    .font(.system(size: 17))
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                                    )
                            }
                            
                            // Template Toggle
                            HStack {
                                Text("템플릿으로 저장")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isTemplate)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                    .tint(AppColor.primary)
                            }
                            .padding(.top, -8) // Pull it closer to the field above
                            
                            // Templates Selection (Existing)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("템플릿 루틴")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
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
                                                        .foregroundColor(.primary)
                                                    Text("(\(template.display))")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(Color.white)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                                )
                                            }
                                        }
                                        
                                        // Saved templates
                                        ForEach(savedTemplates) { routine in
                                            Button(action: {
                                                applyRoutineTemplate(routine)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(routine.name ?? "루틴")
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    Text("(\(getRoutineTimeDisplay(routine)))")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(Color.white)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
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
                            Text("단계 목록")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
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
                                Text("루틴을 만들려면 먼저 단계를 추가해주세요.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                addStep()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("단계 추가")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white) // Changed to white to pop on grouped background
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
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
                        Text("저장")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColor.primary)
                            .cornerRadius(AppRadius.standard)
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.bottom, 10)
                }
                .padding(.top, 10)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
            }
        }
        .navigationTitle(isEditingMode ? "루틴 편집" : "루틴 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .alert("입력 확인", isPresented: $showValidationAlert) {
            Button("확인", role: .cancel) {}
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
        return sortedSteps.map { "\(Int($0.minutes))" }.joined(separator: "/")
    }
    
    private func applyRoutineTemplate(_ routine: Routine) {
        self.routineName = routine.name ?? "루틴"
        let routineSteps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = routineSteps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        self.steps = sortedSteps.map { step in
            let minutes = String(format: "%02d", step.minutes)
            let seconds = String(format: "%02d", step.seconds)
            return RoutineStepData(name: step.type ?? "작업", duration: minutes + seconds)
        }
    }
    
    private func addStep() {
        steps.append(RoutineStepData(name: "", duration: ""))
    }
    
    private func loadSavedTemplates() {
        savedTemplates = CoreDataManager.shared.fetchTemplateRoutines()
    }
    
    private func saveRoutine() {
        guard !routineName.isEmpty else {
            showValidation(message: "루틴 이름을 입력해주세요.")
            return
        }
        guard !steps.isEmpty else {
            showValidation(message: "단계를 최소 1개 추가해주세요.")
            return
        }
        guard !steps.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            showValidation(message: "단계 이름을 입력해주세요.")
            return
        }
        guard !steps.contains(where: { isZeroDuration($0.duration) }) else {
            showValidation(message: "시간을 00:00:00 이상으로 입력해주세요.")
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
            let minutes: Int16
            let seconds: Int16
            
            if step.duration.count >= 3 {
                let minuteString = String(step.duration.dropLast(2))
                let secondString = String(step.duration.suffix(2))
                minutes = Int16(Int(minuteString) ?? 0)
                seconds = Int16(Int(secondString) ?? 0)
            } else {
                // 2글자 이하는 초로 해석
                minutes = 0
                seconds = Int16(Int(step.duration) ?? 0)
            }
            
            CoreDataManager.shared.createRoutineStep(
                routine: targetRoutine,
                order: Int16(index),
                type: step.name,
                minutes: minutes,
                seconds: seconds
            )
        }
        
        // CoreData 저장
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to save routine: \(error)")
        }
        dismiss()
    }

    private func isZeroDuration(_ duration: String) -> Bool {
        let digits = duration.filter { "0123456789".contains($0) }
        guard !digits.isEmpty else { return true }
        if digits.count <= 2 {
            return (Int(digits) ?? 0) == 0
        }
        let minutesEndIndex = digits.index(digits.endIndex, offsetBy: -2)
        let minutes = Int(digits[..<minutesEndIndex]) ?? 0
        let seconds = Int(digits[minutesEndIndex...]) ?? 0
        return minutes == 0 && seconds == 0
    }

    private func showValidation(message: String) {
        validationMessage = message
        showValidationAlert = true
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
                let minutes = String(format: "%02d", step.minutes)
                let seconds = String(format: "%02d", step.seconds)
                return RoutineStepData(name: step.type ?? "작업", duration: minutes + seconds)
            }
        } else if steps.isEmpty {
            addStep()
        }
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
    var duration: String // Just digits, e.g. "2500" for 25:00 (total minutes + seconds)
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
    
    var body: some View {
        HStack(spacing: 8) {
            // Drag Handle (Left)
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.system(size: 20))
                .padding(.trailing, 4)
                .onDrag {
                    self.draggingItem = step
                    return NSItemProvider(object: step.id.uuidString as NSString)
                }
            
            // Name Input
            TextField("단계 이름", text: $step.name)
                .font(.system(size: 16))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .frame(minWidth: 100, maxWidth: .infinity)
                .layoutPriority(1)
            
            // Time Input (Button + Bottom Sheet)
            TimePickerButton(duration: $step.duration)
                .frame(width: 120)
                .background(Color(UIColor.systemGray6))
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

struct TimePickerButton: View {
    @Binding var duration: String
    @State private var isSheetPresented = false
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        Button(action: {
            syncPickerFromStorage()
            isSheetPresented = true
        }) {
            HStack(spacing: 6) {
                Text(formatDisplayFromStorage(duration))
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
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

    private let hourRange = Array(0...99)
    private let minuteSecondRange = Array(0...59)

    var body: some View {
        VStack(spacing: 0) {
            Text("시간 설정")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                Picker("시간", selection: $hours) {
                    ForEach(hourRange, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("분", selection: $minutes) {
                    ForEach(minuteSecondRange, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("초", selection: $seconds) {
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
                Text("시간")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Text("분")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Text("초")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, -8)

            Button(action: onDone) {
                Text("완료")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.primary)
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
