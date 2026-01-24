
import SwiftUI
import CoreData

struct RoutineListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        entity: Routine.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Routine.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == false")
    ) var routines: FetchedResults<Routine>
    
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
                                    CDRoutineCard(routine: routine)
                                }
                            }
                            .padding(.horizontal, AppSpacing.mediumPlus)
                        }
                    }
                    .padding(.top, AppSpacing.medium)
                    
                    // Section: 루틴 추가 버튼
                    NavigationLink(destination: RoutineCreateView()) {
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
    @State private var showConfigSheet = false
    @State private var startTimer = false
    
    var timeStepsDisplay: String {
        let steps = routine.steps as? Set<RoutineStep> ?? []
        let sortedSteps = steps.sorted { ($0.order, $0.stepId?.uuidString ?? "") < ($1.order, $1.stepId?.uuidString ?? "") }
        return sortedSteps.map { "\($0.minutes)m" }.joined(separator: " · ")
    }
    
    var body: some View {
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
                if let createdAt = routine.createdAt {
                    Text("생성일: \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(hex: "F2F2F7"))
                        .cornerRadius(8)
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
            NotificationModeSheet(onStart: {
                startTimer = true
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $startTimer) {
            TimerRunningView()
        }
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
            NotificationModeSheet(onStart: {
                startTimer = true
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $startTimer) {
            TimerRunningView()
        }
    }
}

#Preview {
    RoutineListView()
}
