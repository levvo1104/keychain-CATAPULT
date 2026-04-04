import SwiftUI
import Combine

// MARK: - Models
enum Gender: String, CaseIterable {
    case woman = "woman"
    case man = "man"
    case inBetween = "the in-between"
    case otherOrPreferNot = "other/prefer not to answer"
}

enum AgeRange: String, CaseIterable {
    case under18 = "under 18"
    case eighteernTo24 = "18 - 24"
    case twentyFiveTo40 = "25 - 40"
    case fortyPlus = "40+"
    case preferNot = "prefer not to answer"
}

enum HabitFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
}

// MARK: - OnboardingState
class OnboardingState: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var userName: String = ""
    @Published var gender: Gender? = nil
    @Published var ageRange: AgeRange? = nil
    @Published var createdHabits: [CreatedHabit] = []
    @Published var showHabitSheet: Bool = false

    let totalSteps = 5

    struct CreatedHabit: Identifiable {
        let id = UUID()
        var name: String
        var frequency: HabitFrequency
        var timesCount: Int
        var color: Color
    }

    func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            if currentStep < totalSteps - 1 {
                currentStep += 1
            }
        }
    }

    func goBack() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
}

// MARK: - AccountCreationView (Root)
struct AccountCreationView: View {
    @StateObject private var state = OnboardingState()
    @State private var isComplete = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            if isComplete {
                OnboardingCompleteView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                VStack(spacing: 0) {
                    // Top bar: back button + step dots
                    HStack {
                        if state.currentStep > 0 {
                            Button(action: { state.goBack() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.systemGray6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            Color.clear.frame(width: 36, height: 36)
                        }

                        Spacer()
                        StepDotsView(total: state.totalSteps, current: state.currentStep)

                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Step content
                    ZStack {
                        stepView(for: state.currentStep)
                            .id(state.currentStep)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: state.currentStep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Continue button
                    if state.currentStep != 4 || !state.createdHabits.isEmpty {
                        Button(action: {
                            if state.currentStep == state.totalSteps - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isComplete = true
                                }
                            } else {
                                state.advance() // Fixed: added ()
                            }
                        }) {
                            Text(state.currentStep == state.totalSteps - 1 ? "Finish" : "Continue")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(24)
                    }
                }
            }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    func stepView(for step: Int) -> some View {
        switch step {
        case 0: Text("Welcome View")
        case 1: Text("Name View")
        case 2: Text("Gender View")
        case 3: Text("Age View")
        case 4: Text("Habits View")
        default: EmptyView()
        }
    }
}

struct StepDotsView: View {
    let total: Int
    let current: Int
    var body: some View {
        HStack {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct OnboardingCompleteView: View {
    var body: some View {
        Text("Onboarding Complete!")
            .font(.title)
    }
}
