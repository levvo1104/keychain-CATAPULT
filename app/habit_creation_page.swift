import SwiftUI

// MARK: - Frequency Enum

enum HabitFrequency: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case biWeek = "Bi-Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

// MARK: - Habit Creation Modal

struct HabitCreationView: View {
    @Binding var isPresented: Bool

    var onSave: ((String, HabitFrequency, Int, Int, Color) -> Void)? = nil
    
    // Form State
    
    var initialName: String = ""
    var initialFrequency: HabitFrequency = .day
    var initialTimesCount: Int = 1
    var initialTotalTimes: Int = 30
    var initialColor: Color = .blue

    @State private var habitName: String = ""
    @State private var frequency: HabitFrequency = .day
    @State private var timesCount: Int = 1
    @State private var totalTimesRequired: Int = 30
    @State private var selectedColor: Color = .blue
    


    // Color options for color wheel
    let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo,
        .purple, .pink, .brown, .gray
    ]

    var body: some View {
        ZStack {
            // Mark: Dimmed blurred background
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Mark: Modal Card
            VStack(spacing: 0) {
            
                // -- Top hero area (blurred) --
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)
                    
                    VStack(spacing: 8) {
                        Text("New Habit")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(1.5)
                            .textCase(.uppercase)
                        
                        // Large + button
                        Button {
                            // [TODO] placeholder: could trigger icon picker
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedColor.opacity(0.18))
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .strokeBorder(selectedColor, lineWidth: 2)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(selectedColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // -- Form fields --
                VStack(alignment: .leading, spacing: 18) {

                    // Habit Name
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Habit Name", systemImage: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)

                        TextField("e.g. Morning Run", text: $habitName)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.systemGray6))
                            )
                            .font(.system(size: 16))
                    }

                    // how often?
                    VStack(alignment: .leading, spacing: 6) {
                        Label("how often?", systemImage: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        HStack {
                            Text("per")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 15))
                            
                            Spacer()

                            Picker("Frequency", selection: $frequency) {
                                ForEach(HabitFrequency.allCases) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(selectedColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedColor.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }

                    // how much?
                    VStack(alignment: .leading, spacing: 6) {
                        Label("how much pookie?", systemImage: "number")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        HStack {
                            Text("\(timesCount) time\(timesCount == 1 ? "" : "s")")
                                .font(.system(size: 15))
                                Spacer()
                                Stepper("", value: $timesCount, in: 1...99)
                                    .labelsHidden()
                                    .tint(selectedColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }

                    // total required
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Total Goal", systemImage: "flag.checkered")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)

                        HStack {
                            Text("\(totalTimesRequired) total")
                                .font(.system(size: 15))
                            Spacer()
                            Stepper("", value: $totalTimesRequired, in: 1...9999)
                                .labelsHidden()
                                .tint(selectedColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }

                    // Customization - Color Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Customizations", systemImage: "paintpalette")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)

                        HStack(spacing: 0) {
                            Text("Color")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 14)
                            
                            Spacer()

                            // Inline color swatches
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(colorOptions, id: \.self) { color in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedColor = color
                                            }
                                        } label: {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 26, height: 26)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(.white, lineWidth: 2)
                                                        .opacity(selectedColor == color ? 1 : 0)
                                                )
                                                .shadow(color: color.opacity(0.4), radius: 3)
                                                .scaleEffect(selectedColor == color ? 1.2 : 1.0)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)

                Spacer(minLength: 24)

                // -- Done Button --
                Button {
                    guard !habitName.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return
                    }
                    onSave?(habitName.trimmingCharacters(in: .whitespaces), frequency, timesCount, totalTimesRequired, selectedColor)
                    isPresented = false
                    // [TODO] save habit
                    isPresented = false
                } label: {
                    Text("Done!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(habitName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color(.systemGray6)
                                    : selectedColor
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 10)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 60)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isPresented)
        .onAppear {
                    habitName = initialName
                    frequency = initialFrequency
                    timesCount = initialTimesCount
                    totalTimesRequired = initialTotalTimes
                    selectedColor = initialColor
                }
    }
}

// MARK: - Preview

#Preview {
    HabitCreationView(isPresented: .constant(true))
}
