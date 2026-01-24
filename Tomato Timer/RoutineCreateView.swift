 import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct RoutineCreateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var routineName: String = ""
    @State private var steps: [RoutineStepData] = [
        RoutineStepData(name: "작업", duration: "2500"),
        RoutineStepData(name: "휴식", duration: "0500")
    ]
    @State private var isTemplate: Bool = false
    @State private var savedTemplates: [Routine] = []
    
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
                                                    Text("(저장됨)")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.orange)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(Color.white)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.orange, lineWidth: 1)
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
                        .padding(.horizontal, AppSpacing.mediumPlus)
                        .padding(.bottom, 32)
                        .buttonStyle(PlainButtonStyle())
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
        .navigationTitle("루틴 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            onAppear()
        }
    }
    
    // Logic
    private func applyTemplate(_ template: RoutineTemplate) {
        self.steps = template.steps
        self.routineName = template.name
    }
    
    private func applyRoutineTemplate(_ routine: Routine) {
        self.routineName = routine.name ?? "루틴"
        let routineSteps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = routineSteps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        self.steps = sortedSteps.map { step in
            let minutes = String(format: "%02d", step.minutes)
            let seconds = "00"
            return RoutineStepData(name: step.type ?? "작업", duration: minutes + seconds)
        }
    }
    
    private func addStep() {
        steps.append(RoutineStepData(name: "", duration: "0000"))
    }
    
    private func loadSavedTemplates() {
        savedTemplates = CoreDataManager.shared.fetchTemplateRoutines()
    }
    
    private func saveRoutine() {
        guard !routineName.isEmpty else { return }
        
        let routine = CoreDataManager.shared.createRoutine(name: routineName)
        CoreDataManager.shared.updateRoutine(routine, isTemplate: isTemplate)
        
        for (index, step) in steps.enumerated() {
            let minutes = Int16(Int(step.duration.prefix(2)) ?? 0)
            let stepType = step.name.lowercased().contains("휴") ? "break" : "focus"
            CoreDataManager.shared.createRoutineStep(
                routine: routine,
                order: Int16(index),
                type: stepType,
                minutes: minutes
            )
        }
        
        dismiss()
    }
    
    func onAppear() {
        loadSavedTemplates()
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
    var duration: String // Just digits, e.g. "2500" for 25:00
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
            
            // Time Input (Numbers Only)
            TimeInput(text: $step.duration)
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

struct TimeInput: View {
    @Binding var text: String
    
    var body: some View {
        TextField("00:00", text: Binding(
            get: {
                format(text)
            },
            set: { newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered.count <= 4 {
                    text = filtered
                }
            }
        ))
        .keyboardType(.numberPad)
        .font(.system(size: 16, design: .monospaced))
        .multilineTextAlignment(.center)
        .padding(.vertical, 10)
    }
    
    func format(_ raw: String) -> String {
        var str = raw
        if raw.count > 4 { str = String(raw.prefix(4)) }
        if str.count > 2 {
            let index = str.index(str.startIndex, offsetBy: 2)
            return "\(str[..<index]):\(str[index...])"
        }
        return str
    }
}

#Preview {
    NavigationStack {
        RoutineCreateView()
    }
}
