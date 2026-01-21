import SwiftUI
import UniformTypeIdentifiers

struct RoutineCreateView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var routineName: String = ""
    @State private var steps: [RoutineStep] = [
        RoutineStep(name: "작업", duration: "2500"),
        RoutineStep(name: "휴식", duration: "0500")
    ]
    
    @State private var draggingItem: RoutineStep?
    
    let templates = [
        RoutineTemplate(name: "출근 루틴", display: "30/10/20", steps: [
            RoutineStep(name: "준비", duration: "3000"),
            RoutineStep(name: "이동", duration: "1000"),
            RoutineStep(name: "도착", duration: "2000")
        ]),
        RoutineTemplate(name: "수업 루틴", display: "50/10/50/10", steps: [
            RoutineStep(name: "수업 1", duration: "5000"),
            RoutineStep(name: "쉬는시간", duration: "1000"),
            RoutineStep(name: "수업 2", duration: "5000"),
            RoutineStep(name: "정리", duration: "1000")
        ])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                // MARK: - Header Section
                Section {
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
                        
                        // Templates
                        VStack(alignment: .leading, spacing: 8) {
                            Text("템플릿 루틴")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(templates) { template in
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
                                            .background(Color(UIColor.systemGray6))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                // MARK: - Step List Section
                Section(header: Text("단계 목록").font(.system(size: 14, weight: .medium)).foregroundColor(.gray)) {
                    ForEach($steps) { $step in
                        RoutineStepRow(step: $step, onDelete: {
                            if let index = steps.firstIndex(where: { $0.id == step.id }) {
                                steps.remove(at: index)
                            }
                        })
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.mediumPlus, bottom: 4, trailing: AppSpacing.mediumPlus))
                        .listRowBackground(Color.clear)
                        .onDrag {
                            self.draggingItem = step
                            return NSItemProvider(object: step.id.uuidString as NSString)
                        }
                        .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: step, listData: $steps, current: $draggingItem))
                    }
                }
                
                // Add Button Section
                Section {
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
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: AppSpacing.mediumPlus, bottom: 32, trailing: AppSpacing.mediumPlus))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            
            // MARK: - Bottom Action Button
            VStack {
                Button(action: {
                    dismiss()
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
        .navigationTitle("루틴 만들기")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Logic
    private func applyTemplate(_ template: RoutineTemplate) {
        self.steps = template.steps
        self.routineName = template.name
    }
    
    private func addStep() {
        steps.append(RoutineStep(name: "", duration: "0000"))
    }
}

// MARK: - Drag & Drop Logic
struct DragRelocateDelegate: DropDelegate {
    let item: RoutineStep
    @Binding var listData: [RoutineStep]
    @Binding var current: RoutineStep?

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

struct RoutineStep: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var duration: String // Just digits, e.g. "2500" for 25:00
}

struct RoutineTemplate: Identifiable {
    let id = UUID()
    let name: String
    let display: String
    let steps: [RoutineStep]
}

struct RoutineStepRow: View {
    @Binding var step: RoutineStep
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.system(size: 20))
            
            // Name Input
            TextField("단계 이름", text: $step.name)
                .font(.system(size: 16))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .frame(width: 150)
            
            // Time Input (Numbers Only)
            TimeInput(text: $step.duration)
                .frame(width: 70)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(6)
            
            Spacer().frame(width: 4)
            
            // Delete Icon
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            
            Spacer()
        }
        .padding(12)
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
