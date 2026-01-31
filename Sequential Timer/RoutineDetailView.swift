
import SwiftUI
import CoreData

struct RoutineDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.themePalette) private var theme
    
    let routine: Routine
    @State private var isEditing = false
    
    var sortedSteps: [RoutineStep] {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        return steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                if isEditing {
                    RoutineCreateView(routine: routine)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 루틴 이름
                            VStack(alignment: .leading, spacing: 8) {
                                Text("routine.detail.title.name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, 4)
                                
                                Text(routine.name ?? String(localized: "app.routine.defaultName"))
                                    .font(AppFont.headline())
                                    .foregroundColor(theme.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(theme.surface)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, AppSpacing.mediumPlus)
                            
                            // 생성일
                            if let createdAt = routine.createdAt {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("routine.detail.title.createdAt")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondary)
                                        .padding(.leading, 4)
                                    
                                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.textPrimary)
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(theme.surface)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, AppSpacing.mediumPlus)
                            }
                            
                            // 단계 목록
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(format: String(localized: "routine.detail.steps.title"), sortedSteps.count))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, 4)
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                
                                if sortedSteps.isEmpty {
                                    VStack(alignment: .center, spacing: 8) {
                                        Image(systemName: "list.bullet.indent")
                                            .font(.system(size: 32))
                                            .foregroundColor(theme.textSecondary)
                                        
                                        Text("routine.detail.steps.empty")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(32)
                                    .background(theme.surface)
                                    .cornerRadius(12)
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(Array(sortedSteps.enumerated()), id: \.element.stepId) { index, step in
                                            HStack(spacing: 12) {
                                                VStack(alignment: .center, spacing: 0) {
                                                    Text("\(index + 1)")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 28, height: 28)
                                                        .background(theme.accent)
                                                        .clipShape(Circle())
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(step.title ?? String(localized: "app.step.defaultName"))
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(theme.textPrimary)
                                                    
                                                    Text(formatDuration(Int(step.durationSeconds)))
                                                        .font(.system(size: 13))
                                                        .foregroundColor(theme.textSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                VStack(alignment: .trailing, spacing: 0) {
                                                    Text(formatDigitalDuration(Int(step.durationSeconds)))
                                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                                        .foregroundColor(theme.accent)
                                                }
                                            }
                                            .padding(12)
                                            .background(theme.surface)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                }
                            }
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.vertical, AppSpacing.medium)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(theme.textPrimary)
                                .font(.system(size: 18, weight: .medium))
                    }
                }
                
                if !isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(theme.accent)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                deleteRoutine()
                            }) {
                                Label("common.delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(theme.accent)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteRoutine() {
        managedObjectContext.delete(routine)
        try? managedObjectContext.save()
        dismiss()
    }

    private func formatDuration(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: String(localized: "duration.long.hms"), hours, minutes, secs)
        }
        if minutes > 0 {
            return String(format: String(localized: "duration.long.ms"), minutes, secs)
        }
        return String(format: String(localized: "duration.long.s"), secs)
    }

    private func formatDigitalDuration(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    let stub = Routine()
    RoutineDetailView(routine: stub)
}
