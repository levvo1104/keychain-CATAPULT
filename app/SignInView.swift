import SwiftUI
import Combine
// MARK: - App Session (shared auth state)

/// Drop an instance of AppSession into your environment at the app root
/// so any view can read or mutate the signed-in state.
class AppSession: ObservableObject {
    @Published var isSignedIn: Bool = false

    func signIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isSignedIn = true
        }
    }

    func signOut() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isSignedIn = false
        }
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject var session: AppSession

    // Mode toggle
    @State private var isCreatingAccount = false

    // Fields
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var appeared = false

    // MARK: Validation

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var passwordIsValid: Bool {
        password.count >= 8
    }

    private var confirmMatches: Bool {
        password == confirmPassword
    }

    private var canSubmit: Bool {
        if isCreatingAccount {
            return emailIsValid && passwordIsValid && confirmMatches
        } else {
            return emailIsValid && !password.isEmpty
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // -- Logo / wordmark --
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: 72, height: 72)
                            Image(systemName: "link")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)

                        Text("keychain")
                            .font(.system(size: 32, weight: .bold))
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.08), value: appeared)

                        Text(isCreatingAccount ? "create your account" : "welcome back")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.14), value: appeared)
                            .animation(.easeInOut(duration: 0.2), value: isCreatingAccount)
                    }
                    .padding(.bottom, 44)

                    // -- Form card --
                    VStack(spacing: 16) {

                        // Email
                        AuthField(
                            icon: "envelope",
                            placeholder: "email",
                            text: $email,
                            keyboardType: .emailAddress,
                            isSecure: false
                        )

                        // Password
                        AuthField(
                            icon: "lock",
                            placeholder: "password",
                            text: $password,
                            keyboardType: .default,
                            isSecure: true
                        )

                        // Confirm password (account creation only)
                        if isCreatingAccount {
                            AuthField(
                                icon: "lock.rotation",
                                placeholder: "confirm password",
                                text: $confirmPassword,
                                keyboardType: .default,
                                isSecure: true
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Inline validation hints
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(error)
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if isCreatingAccount && !confirmPassword.isEmpty && !confirmMatches {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text("passwords don't match")
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }

                        if isCreatingAccount && !password.isEmpty && !passwordIsValid {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text("password must be at least 8 characters")
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCreatingAccount)
                    .animation(.easeInOut(duration: 0.2), value: errorMessage)

                    Spacer(minLength: 32)

                    // -- Submit button --
                    Button {
                        submit()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canSubmit ? Color.primary : Color(.systemGray4))

                            if isLoading {
                                ProgressView()
                                    .tint(Color(.systemBackground))
                            } else {
                                Text(isCreatingAccount ? "create account" : "sign in")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color(.systemBackground))
                            }
                        }
                        .frame(height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || isLoading)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.15), value: canSubmit)

                    // -- Mode toggle --
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCreatingAccount.toggle()
                            errorMessage = nil
                            confirmPassword = ""
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isCreatingAccount ? "already have an account?" : "don't have an account?")
                                .foregroundStyle(.secondary)
                            Text(isCreatingAccount ? "sign in" : "create one")
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: Submit

    private func submit() {
        errorMessage = nil
        isLoading = true

        // TODO: Replace this with your real auth backend call.
        // For now, a short delay simulates a network request.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false

            if isCreatingAccount {
                // Hand off to the onboarding flow (AccountCreationView handles
                // the multi-step profile setup; it calls session.signIn() when done).
                // For a direct sign-in after creation, call session.signIn() here instead.
                session.signIn()
            } else {
                // Simulate a wrong-password failure so you can see the error state.
                // Remove this guard and call session.signIn() unconditionally once
                // you have a real auth check.
                if password == "wrongpassword" {
                    errorMessage = "incorrect email or password"
                } else {
                    session.signIn()
                }
            }
        }
    }
}

// MARK: - Reusable Auth Field

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

#Preview {
    SignInView()
        .environmentObject(AppSession())
}
