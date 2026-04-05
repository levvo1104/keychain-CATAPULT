import SwiftUI
import Combine

// MARK: - Habit Model

struct Habit: Identifiable {
    let id: UUID = UUID()
    var name: String
    var frequency: HabitFrequency
    var timesGoal: Int
    var timesCompleted: Int
    var totalTimesRequired: Int
    var color: Color

    var isCompleted: Bool { timesCompleted >= timesGoal }

    var progressFraction: Double {
        guard timesGoal > 0 else { return 0 }
        return min(Double(timesCompleted) / Double(timesGoal), 1.0)
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var session: AppSession
    @State private var habits: [Habit] = [
        Habit(name: "Morning Run", frequency: .day, timesGoal: 1, timesCompleted: 0, totalTimesRequired: 30, color: .blue),
        Habit(name: "Read 20 Pages", frequency: .day, timesGoal: 1, timesCompleted: 1, totalTimesRequired: 30, color: .green),
    ]
    @State private var showHabitCreation = false
    @State private var showProfile = false

    private var sortedHabits: [Habit] {
        habits.sorted { lhs, rhs in
            if lhs.isCompleted == rhs.isCompleted { return false }
            return !lhs.isCompleted
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // MARK: Habit List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedHabits) { habit in
                            SwipeToDeleteContainer {
                                deleteHabit(id: habit.id)
                            } content: {
                                HabitCard(habit: habit) {
                                logCompletion(for: habit.id)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                        }
                        Spacer(minLength: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: habits.map(\.timesCompleted))
                }

                // MARK: Add Habit Button
                Button {
                    withAnimation { showHabitCreation = true }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 62, height: 62)
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                            .frame(width: 62, height: 62)
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
            }
            .navigationTitle(todayTitle())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showProfile = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 34, height: 34)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: Habit Creation Modal — inside NavigationStack
            .overlay {
                if showHabitCreation {
                    HabitCreationView(isPresented: $showHabitCreation) { name, frequency, count, requiredTime, color in
                        let newHabit = Habit(
                            name: name,
                            frequency: frequency,
                            timesGoal: count,
                            timesCompleted: 0,
                            totalTimesRequired: requiredTime,
                            color: color
                        )
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            habits.append(newHabit)
                        }
                    }
                }
            }

            // MARK: Profile Sheet — inside NavigationStack
            .sheet(isPresented: $showProfile) {
                ProfileSettingsView(onLogOut: {
                    showProfile = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        session.signOut()
                    }
                })
                .environmentObject(session)
            }
        }
    }

    // MARK: Helpers

    func deleteHabit(id: UUID) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            habits.removeAll {
                $0.id == id
            }
        }
    }

    func logCompletion(for id: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if habits[index].timesCompleted < habits[index].timesGoal {
                habits[index].timesCompleted += 1
            }
        }
    }

    func todayTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Swipe to Delete

struct SwipeToDeleteContainer<Content: View>: View {
    let content: Content
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    private let deleteButtonWidth: CGFloat = 72

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed behind card
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = -500
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onDelete()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.red)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
                .frame(width: deleteButtonWidth)
            }
            .buttonStyle(.plain)
            .opacity(offset < 0 ? 1 : 0)

            content.offset(x: offset).gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation < 0 {
                            withAnimation(.interactiveSpring()) {
                                offset = max(translation, -deleteButtonWidth)
                            }
                        } else if offset < 0 {
                            withAnimation(.interactiveSpring()) {
                                offset = min(0, offset + translation)
                            }
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.width
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if offset < -deleteButtonWidth / 2 || velocity < -150 {
                                offset = -deleteButtonWidth
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .clipped()
    }
}

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(habit.color.opacity(habit.isCompleted ? 0.1 : 0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: habit.isCompleted ? "checkmark" : "circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(habit.isCompleted ? habit.color : habit.color.opacity(0.6))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                            .strikethrough(habit.isCompleted, color: .secondary)
                        Text("per \(habit.frequency.rawValue.lowercased())")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text("\(habit.timesCompleted)/\(habit.timesGoal)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(habit.isCompleted ? habit.color : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(habit.isCompleted
                                    ? habit.color.opacity(0.12)
                                    : Color(.systemGray5))
                        )
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 6)
                        Capsule()
                            .fill(habit.isCompleted ? habit.color : habit.color.opacity(0.75))
                            .frame(width: geo.size.width * habit.progressFraction, height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: habit.progressFraction)
                    }
                }
                .frame(height: 6)

                if habit.isCompleted {
                    Text("COMPLETED!")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(habit.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                habit.isCompleted
                                    ? habit.color.opacity(0.25)
                                    : Color(.systemGray4).opacity(0.5),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(habit.isCompleted ? 0.75 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppSession())
}
