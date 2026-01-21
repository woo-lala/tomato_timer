import SwiftUI

// Mock Data Model
struct Routine: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // Emoji
    let duration: String
    let themeColor: Color
}

struct RoutineListView: View {
    // Mock Data
    @State private var myRoutines = [
        Routine(name: "Focus", icon: "🧠", duration: "25 min", themeColor: AppColor.primary),
        Routine(name: "Rest", icon: "☕️", duration: "5 min", themeColor: Color(hex: "26BA67")) // Fitness Green-ish
    ]
    
    let templates = [
        Routine(name: "Work", icon: "💼", duration: "50 min", themeColor: Color(hex: "FFC23F")), // Learning Gold
        Routine(name: "Study", icon: "📚", duration: "45 min", themeColor: Color(hex: "E94E3D")), // Youtube Red-ish
        Routine(name: "Exercise", icon: "🏃", duration: "30 min", themeColor: Color(hex: "26BA67")) // Fitness Green
    ]
    
    @State private var showToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColor.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: AppSpacing.large) { // 24
                            
                            // Section 2: My Routines
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                Text("My Routines")
                                    .font(AppFont.title())
                                    .foregroundColor(AppColor.textPrimary)
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                
                                ForEach(myRoutines) { routine in
                                    RoutineCard(routine: routine)
                                        .padding(.horizontal, AppSpacing.mediumPlus)
                                }
                            }
                            .padding(.top, AppSpacing.mediumPlus)
                            
                            // Section 3: Create Button
                            Button(action: {
                                saveRoutine()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(AppFont.button())
                                    Text("Create New Routine")
                                        .font(AppFont.button())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [AppColor.primary.opacity(0.8), AppColor.primaryStrong]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(AppRadius.standard)
                                .shadow(color: AppColor.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, AppSpacing.mediumPlus)
                            
                            // Section 4: Template Routines
                            VStack(alignment: .leading, spacing: AppSpacing.smallPlus) {
                                Text("Template Routines")
                                    .font(AppFont.headline())
                                    .foregroundColor(AppColor.textSecondary)
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppSpacing.medium) {
                                        ForEach(templates) { template in
                                            TemplateRoutineCard(routine: template)
                                        }
                                    }
                                    .padding(.horizontal, AppSpacing.mediumPlus)
                                    .padding(.bottom, 20) // Shadow space
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Tomato Timer")
                .navigationBarTitleDisplayMode(.inline)
                
                // Toast Message
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "26BA67")) // Success Green
                            Text("Saved to Local Storage (Core Data)")
                                .font(AppFont.callout())
                        }
                        .padding()
                        .background(AppColor.surface)
                        .cornerRadius(25)
                        .shadow(color: AppColor.shadow, radius: 10, x: 0, y: 5)
                        .padding(.bottom, AppSpacing.mediumPlus)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
    }
    
    private func saveRoutine() {
        // Simulate save action
        withAnimation(.spring()) {
            showToast = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Components

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            ZStack {
                Circle()
                    .fill(routine.themeColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(routine.icon)
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(AppFont.headline())
                    .foregroundColor(AppColor.textPrimary)
                
                Text(routine.duration)
                    .font(AppFont.body())
                    .foregroundColor(AppColor.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(AppColor.textSecondary.opacity(0.3))
        }
        .padding(AppSpacing.medium)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.standard)
        .shadow(color: AppColor.shadow, radius: 5, x: 0, y: 2)
    }
}

struct TemplateRoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallPlus) {
            HStack {
                Text(routine.icon)
                    .font(AppFont.title())
                    .padding(10)
                    .background(routine.themeColor.opacity(0.2))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            Spacer()
            
            Text(routine.name)
                .font(AppFont.heading())
                .foregroundColor(AppColor.textPrimary)
            
            Text(routine.duration)
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(AppSpacing.medium)
        .frame(width: 140, height: 140)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.standard)
        .shadow(color: AppColor.shadow, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    RoutineListView()
}
