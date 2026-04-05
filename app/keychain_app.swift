import SwiftUI

@main
struct keychainApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            if session.isSignedIn {
                HomeView()
                    .environmentObject(session)
            } else {
                SignInView()
                    .environmentObject(session)
            }
        }
    }
}
