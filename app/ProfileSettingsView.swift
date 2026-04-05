import SwiftUI
import Combine
 
// MARK: - User Profile Model
class UserProfile: ObservableObject {
    @Published var name: String = "John Doe"
    @Published var pronouns: String = "eg.she/her"
    @Published var age: String = "40+"
    @Published var profileImage: UIImage? = nil
    @Published var notificationsEnabled: Bool = true
    @Published var dailyReminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
}
 
// MARK: - Profile & Settings Root View
struct ProfileSettingsView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dismiss) var dismiss
    var onLogOut: (() -> Void)? = nil  
    @StateObject private var profile = UserProfile()
    @State private var showEditProfile = false
    @State private var showLogOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var deletePasswordEntry = ""
    @State private var deletePasswordWrong = false
 
    // Placeholder correct password for delete guard
    private let deletePassword = "password123"
 
    var body: some View {
        NavigationStack {
            List {
 
                // ── Profile Header ──
                Section {
                    HStack(spacing: 16) {
                        ProfileImageView(image: profile.profileImage)
 
                        VStack(alignment: .leading, spacing: 3) {
                            Text(profile.name)
                                .font(.system(size: 20, weight: .semibold))
                            Text(profile.pronouns)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text(profile.age)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
 
                        Spacer()
 
                        Button("Edit") { showEditProfile = true }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 8)
                }
                
                .onAppear {
                    // Pre-populate from session if profile still has defaults
                    if profile.name == "John Doe" && !session.userName.isEmpty {
                        profile.name = session.userName
                    }
            
                    if profile.age == "40+" && !session.userAge.isEmpty {
                        profile.age = session.userAge
                    }
                }
 
                // ── Settings Rows ──
                Section {
                    NavigationLink(destination: DeviceSetupView()) {
                        SettingsRow(icon: "antenna.radiowaves.left.and.right", color: .blue, label: "Devices")
                    }
                    NavigationLink(destination: FeedbackReportView()) {
                        SettingsRow(icon: "exclamationmark.bubble", color: .orange, label: "Feedback / Report")
                    }
                    NavigationLink(destination: ChangePasswordView()) {
                        SettingsRow(icon: "lock", color: .green, label: "Add / Change Password")
                    }
                    NavigationLink(destination: NotificationsSettingsView(profile: profile)) {
                        SettingsRow(icon: "bell", color: .purple, label: "Notifications")
                    }
                }
 
                // ── Danger Zone ──
                Section {
                    Button(role: .none) {
                        showLogOutConfirm = true
                    } label: {
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", color: .gray, label: "Log Out")
                    }
                    .foregroundStyle(.primary)
 
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        SettingsRow(icon: "trash", color: .red, label: "Delete Profile")
                    }
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.large)
 
            // ── Edit Profile Sheet ──
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: profile)
                
            }
 
            // ── Log Out Confirmation ──
            .confirmationDialog("Log out of your account?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    onLogOut?()
                }
                Button("Cancel", role: .cancel) {}
            }
 
            // ── Delete Profile — password protected ──
            .alert("Delete Profile", isPresented: $showDeleteConfirm) {
                SecureField("Enter your password", text: $deletePasswordEntry)
                Button("Delete", role: .destructive) {
                    if deletePasswordEntry == deletePassword {
                        // TODO: delete account
                    } else {
                        deletePasswordWrong = true
                        deletePasswordEntry = ""
                    }
                }
                Button("Cancel", role: .cancel) { deletePasswordEntry = "" }
            } message: {
                Text("This cannot be undone. Enter your password to confirm.")
            }
            .alert("Incorrect Password", isPresented: $deletePasswordWrong) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The password you entered is incorrect. Profile was not deleted.")
            }
        }
    }
}

// MARK: - Reusable Row
struct SettingsRow: View {
    let icon: String
    let color: Color
    let label: String
 
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(label)
            .font(.system(size: 16))
        }
    }
}
// Mark: - Profile Image View
struct ProfileImageView: View {
    let image: UIImage?
 
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 64, height: 64)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.systemGray2))
            }
        }
    }
}

//==========================
// Mark: edit Profile Sheet
//==========================

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profile: UserProfile
    @State private var draftName: String = ""
    @State private var draftPronouns: String = ""
    @State private var draftAge: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    HStack {
                        Spacer()
                        ProfileImageView(image: profile.profileImage)
                        Spacer()
                }
                //TODO: wire up photosPciker for image selection
                Button("Change Photo") {}
                    .frame(maxWidth: .infinity)
                }
                Section("info") {
                    LabeledContent("Name") {
                        TextField("Full Name", text: $draftName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Pronouns") {
                        TextField("e.g. she/her", text: $draftPronouns)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Age") {
                        TextField("e.g. 40+", text: $draftAge)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !draftName.isEmpty { profile.name = draftName }
                        if !draftPronouns.isEmpty { profile.pronouns = draftPronouns }
                        if !draftAge.isEmpty { profile.age = draftAge }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draftName = profile.name
                draftPronouns = profile.pronouns
                draftAge = profile.age
            }
        }
    }
}

// Mark: feedback / report view
enum FeedbackType: String, CaseIterable, Identifiable {
    case general = "General Feedback"
    case bug = "Report a Bug"
    case other = "Other"
    var id: String { rawValue }
}

struct FeedbackReportView: View {
    @State private var feedbackType: FeedbackType = .general
    @State private var message: String = ""
    @State private var submitted = false

    var body: some View {
        Form {
            Section("Type") {
                Picker("Category", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            Section("Message") {
                TextEditor(text: $message)
                    .frame(minHeight: 150)
            }

            Section {
                Button("Submit") {
                    //todo: send to backend
                    submitted = true
                    message = ""
                }
                .frame(maxWidth: .infinity)
                .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Feedback / Report")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thanks", isPresented: $submitted) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your feedback has been submitted. ")
        }
    }
}

// ============================================================
// MARK: - Change Password View
// ============================================================
struct ChangePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
 
    var passwordsMatch: Bool { newPassword == confirmPassword }
    var isValid: Bool { !currentPassword.isEmpty && newPassword.count >= 8 && passwordsMatch }
 
    var body: some View {
        Form {
            Section("Current Password") {
                SecureField("Enter current password", text: $currentPassword)
            }
 
            Section {
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            } header: {
                Text("New Password")
            } footer: {
                if !newPassword.isEmpty && newPassword.count < 8 {
                    Text("Password must be at least 8 characters.")
                        .foregroundStyle(.red)
                } else if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match.")
                        .foregroundStyle(.red)
                }
            }
 
            Section {
                Button("Update Password") {
                    // TODO: validate against backend
                    showSuccess = true
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
                .frame(maxWidth: .infinity)
                .disabled(!isValid)
            }
        }
        .navigationTitle("Add / Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password has been changed successfully.")
        }
    }
}
 
// ============================================================
// MARK: - Notifications Settings View
// ============================================================
struct NotificationsSettingsView: View {
    @ObservedObject var profile: UserProfile
 
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $profile.notificationsEnabled)
            } footer: {
                Text("Receive reminders and habit updates from the app and your keychain.")
            }
 
            if profile.notificationsEnabled {
                Section("Daily Reminder") {
                    DatePicker("Remind me at", selection: $profile.dailyReminderTime, displayedComponents: .hourAndMinute)
                }
 
                Section("Alert Types") {
                    Toggle("Habit reminders", isOn: .constant(true))
                    Toggle("Button press confirmations", isOn: .constant(true))
                    Toggle("Weekly progress summary", isOn: .constant(false))
                }
                .toggleStyle(.switch)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
 
// MARK: - Preview
struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
            .environmentObject(AppSession())
    }
}
