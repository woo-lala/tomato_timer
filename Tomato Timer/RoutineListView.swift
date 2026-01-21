
import SwiftUI

// Mock Data Model
struct Routine: Identifiable {
    let id = UUID()
    let name: String
    let timeSteps: String
    let lastRun: String
}

struct RoutineListView: View {
    // Mock Data
    @State private var myRoutines = [
        Routine(name: "집중 루틴", timeSteps: "25m · 5m · 25m · 15m", lastRun: "오늘 오전 10:30"),
        Routine(name: "시험 기간", timeSteps: "50m · 10m · 50m", lastRun: "어제 오후 3:15")
    ]
    
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
                        
                        VStack(spacing: 12) {
                            ForEach(myRoutines) { routine in
                                RoutineCard(routine: routine)
                            }
                        }
                        .padding(.horizontal, AppSpacing.mediumPlus)
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
        }
    }
}

// MARK: - Components

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Title and Time Steps
                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.name)
                        .font(AppFont.headline())
                        .foregroundColor(AppColor.textPrimary)
                    
                    Text(routine.timeSteps)
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textSecondary)
                }
                
                // Last Run Badge
                if !routine.lastRun.isEmpty {
                    Text("마지막 실행: \(routine.lastRun)")
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
            NavigationLink(destination: TimerRunningView()) {
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
    }
}

#Preview {
    RoutineListView()
}
