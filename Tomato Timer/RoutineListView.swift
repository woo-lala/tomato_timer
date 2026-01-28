
import SwiftUI
import CoreData

struct RoutineListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        entity: Routine.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Routine.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == false")
    ) var routines: FetchedResults<Routine>
    
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Section: 내 루틴
                    VStack(alignment: .leading, spacing: 16) {
                        Text("내 루틴")
                            .font(AppFont.title())
                            .foregroundColor(.black)
                            .padding(.horizontal, AppSpacing.mediumPlus)
                        
                        if routines.isEmpty {
                            Text("아직 루틴이 없습니다.")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(routines) { routine in
                                    CDRoutineCard(routine: routine, refreshTrigger: $refreshTrigger)
                                }
                            }
                            .padding(.horizontal, AppSpacing.mediumPlus)
                        }
                    }
                    .padding(.top, AppSpacing.medium)
                    .id(refreshTrigger)
                    
                    // Section: 루틴 추가 버튼
                    NavigationLink(destination: RoutineCreateView(routine: nil)) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("루틴 추가")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea(.all))
            .preferredColorScheme(.light)
            .navigationTitle("내 루틴")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .sessionStarted)) { _ in
                refreshTrigger = UUID()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct CDRoutineCard: View {
    let routine: Routine
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var refreshTrigger: UUID
    
    @State private var showConfigSheet = false
    @State private var startTimer = false
    @State private var showEditView = false
    @State private var selectedConfiguration: NotificationConfiguration = .default
    @State private var selectedTransitionMode: StepTransitionMode = .manual
    
    var timeStepsDisplay: String {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        let maxShown = 3
        let shownSteps = sortedSteps.prefix(maxShown).map { step in
            formatCompactDuration(Int(step.durationSeconds))
        }
        let remainingCount = max(sortedSteps.count - maxShown, 0)
        if remainingCount > 0 {
            let prefix = shownSteps.joined(separator: " · ")
            return "\(prefix)  외 \(remainingCount)개"
        }
        return shownSteps.joined(separator: " · ")
    }

    var lastRunDisplay: String {
        if let date = lastRunDate {
            return "마지막 실행: \(formatDate(date))"
        }
        if let createdAt = routine.createdAt {
            return "생성일: \(formatDate(createdAt))"
        }
        if let updatedAt = routine.updatedAt {
            return "마지막 수정: \(formatDate(updatedAt))"
        }
        return "생성일: 없음"
    }

    var lastRunDate: Date? {
        let sessions = routine.sessions as? Set<Session> ?? []
        return sessions.compactMap { $0.startedAt }.max()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Time Steps
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.name ?? "루틴")
                            .font(AppFont.headline())
                            .foregroundColor(AppColor.textPrimary)
                        
                        Text(timeStepsDisplay.isEmpty ? "스텝 없음" : timeStepsDisplay)
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    
                    // Created Date Badge
                    Text(lastRunDisplay)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(hex: "F2F2F7"))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Play Button
                Button(action: {
                    showConfigSheet = true
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(AppColor.primary)
                        .clipShape(Circle())
                        .shadow(color: AppColor.primary.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .padding(16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                showEditView = true
            }
        }
        .background(Color.white)
        .cornerRadius(AppRadius.standard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(Color(hex: "F2F2F7"), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                deleteRoutine()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteRoutine()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showConfigSheet) {
            NotificationModeSheet(routine: routine, onStart: { selectedRoutine, config, transitionMode in
                selectedConfiguration = config
                selectedTransitionMode = transitionMode
                startTimer = true
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $startTimer) {
            TimerRunningView(routine: routine, initialConfiguration: selectedConfiguration, initialStepTransitionMode: selectedTransitionMode, forceNewSession: true)
        }
        .navigationDestination(isPresented: $showEditView) {
            RoutineCreateView(routine: routine)
                .onDisappear {
                    // 편집 화면에서 돌아올 때 리스트 갱신
                    refreshTrigger = UUID()
                }
        }
    }
    
    private func deleteRoutine() {
        managedObjectContext.delete(routine)
        do {
            try managedObjectContext.save()
            refreshTrigger = UUID()
        } catch {
            print("Failed to delete routine: \(error)")
        }
    }

    private func formatCompactDuration(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            if minutes > 0 && secs > 0 {
                return "\(hours)h \(minutes)m \(secs)s"
            }
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h \(secs)s"
        }
        if minutes > 0 && secs > 0 {
            return "\(minutes)m \(secs)s"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(secs)s"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct RoutineCard: View {
    let routine: Routine
    @State private var showConfigSheet = false
    @State private var startTimer = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Title and Time Steps
                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.name ?? "루틴")
                        .font(AppFont.headline())
                        .foregroundColor(AppColor.textPrimary)
                    
                    Text("")
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            
            Spacer()
            
            // Play Button
            Button(action: {
                showConfigSheet = true
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(AppColor.primary)
                    .clipShape(Circle())
                    .shadow(color: AppColor.primary.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(AppRadius.standard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(Color(hex: "F2F2F7"), lineWidth: 1)
        )
        .sheet(isPresented: $showConfigSheet) {
            NotificationModeSheet(routine: routine, onStart: { selectedRoutine, config, transitionMode in
                startTimer = true
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $startTimer) {
            TimerRunningView(routine: routine, initialConfiguration: nil, initialStepTransitionMode: .manual, forceNewSession: true)
        }
    }
}

#Preview {
    RoutineListView()
}
