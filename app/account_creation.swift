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

// MARK: - OnboardingState

class OnboardingState: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var userName: String = ""
    @Published var gender: Gender? = nil
    @Published var ageRange: AgeRange? = nil
    @Published var createdHabits: [CreatedHabit] = []
    @Published var showHabitSheet: Bool = false

    let totalSteps = 5 // welcome, name, gender, age, habits

    struct CreatedHabit: Identifiable {
        let id = UUID()
        var name: String
        var frequency: HabitFrequency
        var timesCount: Int
        var totalTimesRequired: Int
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

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return gender != nil
        case 3: return ageRange != nil
        case 4: return !createdHabits.isEmpty
        default: return false
        }
    }
}

// MARK: - AccountCreationView (Root)

struct AccountCreationView: View {
    @StateObject private var state = OnboardingState()
    @State private var isComplete = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

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
                                    .background(Color(.systemGray6))
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
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.currentStep)
                
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
                                state.advance()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(state.currentStep == state.totalSteps - 1 ? "Let's Go!" : "Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(state.canAdvance ? Color.primary : Color(.systemGray4))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!state.canAdvance)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .animation(.easeInOut(duration: 0.2), value: state.canAdvance)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.createdHabits.count)
            }

            // Habit creation sheet
            if state.showHabitSheet {
                HabitCreationView(isPresented: $state.showHabitSheet) { name, frequency, timesCount, totalTimesRequired, color in
                    let habit = OnboardingState.CreatedHabit(
                        name: name,
                        frequency: frequency,
                        timesCount: timesCount,
                        totalTimesRequired: totalTimesRequired,
                        color: color
                    )
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        state.createdHabits.append(habit)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: state.showHabitSheet)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isComplete)
    }

    @ViewBuilder
    func stepView(for step: Int) -> some View {
        switch step {
            case 0: WelcomeStepView()
            case 1: NameStepView(name: $state.userName)
            case 2: GenderStepView(selected: $state.gender)
            case 3: AgeStepView(selected: $state.ageRange)
            case 4: HabitOnboardingStepView(
                habits: $state.createdHabits,
                showSheet: $state.showHabitSheet
            )
            default: EmptyView()
        }
    }
}

// MARK: - Step Dots

struct StepDotsView: View {
    let total: Int
    let current: Int
 
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.primary : Color(.systemGray4))
                    .frame(width: i == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: current)
            }
        }
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStepView: View {
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("hi, ")
                    .font(.system(size: 52, weight: .bold))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                
                Text("about us")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)
                    .italic()
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)
            }

            Text("sincerely,\n4 sleep-deprived Purdue students")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Step 1: Name

struct NameStepView: View {
    @Binding var name: String
    @State private var appeared = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("what do you go by?")
                    .font(.system(size: 32, weight: .bold))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
 
                Text("we'll use this to personalize your experience.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.08), value: appeared)
            }

            TextField("your name...", text: $name)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(focused ? Color.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
                .focused($focused)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focused = true
            }
        }
    }
}

// MARK: - Step 2: Gender

struct GenderStepView: View {
    @Binding var selected: Gender?
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
 
            Text("how do you identify?")
                .font(.system(size: 32, weight: .bold))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
 
            VStack(spacing: 10) {
                ForEach(Array(Gender.allCases.enumerated()), id: \.element) { index, option in
                    OnboardingSelectionRow(
                        label: option.rawValue,
                        isSelected: selected == option,
                        delay: Double(index) * 0.06 + 0.1,
                        appeared: appeared
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selected = option }
                    }
                }
            }
 
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Step 3: Age

struct AgeStepView: View {
    @Binding var selected: AgeRange?
    @State private var appeared = false
 
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("age?")
                .font(.system(size: 40, weight: .bold))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
 
            VStack(spacing: 10) {
                ForEach(Array(AgeRange.allCases.enumerated()), id: \.element) { index, option in
                    OnboardingSelectionRow(
                        label: option.rawValue,
                        isSelected: selected == option,
                        delay: Double(index) * 0.06 + 0.1,
                        appeared: appeared
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selected = option
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Step 4: Habits Onboarding

struct HabitOnboardingStepView: View {
    @Binding var habits: [OnboardingState.CreatedHabit]
    @Binding var showSheet: Bool
    @State private var appeared = false
 
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("what habits would\nyou like to build?")
                    .font(.system(size: 32, weight: .bold))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
 
                Text("add at least one to get started.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.08), value: appeared)
            }

            // Created habits list
            if !habits.isEmpty {
                VStack(spacing: 8) {
                    ForEach(habits) { habit in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(habit.color)
                                .frame(width: 11, height: 11)
                            Text(habit.name)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text("\(habit.timesCount)x / \(habit.frequency.rawValue)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: habits.count)
            }

            // Create your own habit button
            Button(action: { showSheet = true }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 30, height: 30)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(.systemBackground))
                    }
                    Text(habits.isEmpty ? "Create your own!" : "Add another habit")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(.plain)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Shared: Onboarding Selection Row

struct OnboardingSelectionRow: View {
    let label: String
    let isSelected: Bool
    let delay: Double
    let appeared: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(.systemBackground))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.primary : Color(.systemGray6))
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Completion Screen

struct OnboardingCompleteView: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🎉")
                .font(.system(size: 72))
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
            
            VStack(spacing: 8) {
                Text("you're all set!")
                    .font(.system(size: 36, weight: .bold))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
 
                Text("let's start building those habits...")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.22), value: appeared)
            }
            Spacer()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AccountCreationView()
}
