
import SwiftUI
import CoreData

struct RoutineListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.themePalette) private var theme
    @EnvironmentObject private var languageStore: LanguageStore
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
                        Text("routine.list.title")
                            .font(AppFont.title())
                            .foregroundColor(theme.textPrimary)
                            .padding(.horizontal, AppSpacing.mediumPlus)
                        
                        if routines.isEmpty {
                            Text("routine.list.empty")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textSecondary)
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
                            Text("routine.list.add")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.surface)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                }
                .padding(.bottom, 40)
            }
            .background(theme.background.ignoresSafeArea(.all))
            .navigationTitle("routine.list.title")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .sessionStarted)) { _ in
                refreshTrigger = UUID()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView().id(languageStore.selection)) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .id(languageStore.selection)
    }
}

// MARK: - Components

struct CDRoutineCard: View {
    let routine: Routine
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.themePalette) private var theme
    
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
            return String(format: String(localized: "routine.list.steps.more"), prefix, remainingCount)
        }
        return shownSteps.joined(separator: " · ")
    }

    var lastRunDisplay: String {
        if let date = lastRunDate {
            return String(format: String(localized: "routine.list.lastRun"), formatDate(date))
        }
        if let createdAt = routine.createdAt {
            return String(format: String(localized: "routine.list.createdAt"), formatDate(createdAt))
        }
        if let updatedAt = routine.updatedAt {
            return String(format: String(localized: "routine.list.updatedAt"), formatDate(updatedAt))
        }
        return String(localized: "routine.list.createdAt.none")
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
                        Text(routine.name ?? String(localized: "app.routine.defaultName"))
                            .font(AppFont.headline())
                            .foregroundColor(theme.textPrimary)
                        
                        Text(timeStepsDisplay.isEmpty ? String(localized: "routine.list.steps.none") : timeStepsDisplay)
                            .font(AppFont.body())
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    // Created Date Badge
                    Text(lastRunDisplay)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(theme.background)
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
                        .background(theme.accent)
                        .clipShape(Circle())
                        .shadow(color: theme.accent.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .padding(16)
            .background(theme.surface)
            .contentShape(Rectangle())
            .onTapGesture {
                showEditView = true
            }
        }
        .background(theme.surface)
        .cornerRadius(AppRadius.standard)
        .shadow(color: theme.shadow, radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(theme.border, lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                deleteRoutine()
            } label: {
                Label("common.delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteRoutine()
            } label: {
                Label("common.delete", systemImage: "trash")
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
                return String(format: String(localized: "duration.compact.hms"), hours, minutes, secs)
            }
            if minutes > 0 {
                return String(format: String(localized: "duration.compact.hm"), hours, minutes)
            }
            return String(format: String(localized: "duration.compact.hs"), hours, secs)
        }
        if minutes > 0 && secs > 0 {
            return String(format: String(localized: "duration.compact.ms"), minutes, secs)
        }
        if minutes > 0 {
            return String(format: String(localized: "duration.compact.m"), minutes)
        }
        return String(format: String(localized: "duration.compact.s"), secs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct RoutineCard: View {
    let routine: Routine
    @Environment(\.themePalette) private var theme
    @State private var showConfigSheet = false
    @State private var startTimer = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Title and Time Steps
                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.name ?? String(localized: "app.routine.defaultName"))
                        .font(AppFont.headline())
                        .foregroundColor(theme.textPrimary)
                    
                    Text("")
                        .font(AppFont.body())
                        .foregroundColor(theme.textSecondary)
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
                        .background(theme.accent)
                        .clipShape(Circle())
                        .shadow(color: theme.accent.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
        .padding(16)
        .background(theme.surface)
        .cornerRadius(AppRadius.standard)
        .shadow(color: theme.shadow, radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(theme.border, lineWidth: 1)
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
