# unlock-CATAPULT
🔑 Unlock
A habit tracking iOS app built during Catapult — designed to make logging habits as frictionless as possible.

What It Does
Unlock lets you build and track habits over time. Each habit has a daily (or weekly, monthly, etc.) goal alongside a long-term total target — so you're always working toward both the day's small win and the bigger picture. A progress bar and live countdown ("8 left") keep you oriented at a glance.
Core features:

Create habits with a name, color, frequency, per-period count, and an all-time total goal
Tap a card to log a completion — the progress bar fills in real time
Completed habits sink to the bottom automatically, keeping your active ones front and center
Swipe left on any card to delete it
Full sign-in / sign-up flow with email and password validation
Multi-step onboarding to set up your profile and first habits
Profile page with notification settings, daily reminder time, and password management


Built With

SwiftUI — all UI, animations, and navigation
Combine — reactive state with ObservableObject / @Published
Unlock(keychain) — secure credential storage


Architecture
FileResponsibilitykeychain_app.swiftApp entry point; routes to HomeView or SignInView based on AppSessionSignInView.swiftSign in / create account with inline validation; houses AppSessionaccount_creation.swift5-step onboarding flow (OnboardingState drives step progression)homeView.swiftHabit list, Habit model, HabitCard, swipe-to-delete, add buttonhabit_creation_page.swiftModal for creating a new habit (name, frequency, count, total goal, color)ProfileSettingsView.swiftProfile editing, notifications, password change, feedback, device settingsDeviceSetupView.swiftKeychain hardware device pairing

Getting Started

Clone the repo

bash   git clone https://github.com/levvo1104/keychain-CATAPULT.git

Open keychain.xcodeproj in Xcode
Select a simulator or connected device running iOS 17+
Hit Run


No external dependencies or package manager setup required.


Notes

Habit data is currently stored in local @State — persistence (Core Data or iCloud) is a planned next step
The physical keychain button integration is in progress via DeviceSetupView
Password validation on the delete-account flow uses a placeholder; wire up your real auth backend in ProfileSettingsView
