//
//  keychain_app.swift
//  keychain
//
//  Created by Annetti Ruiz millán on 4/4/26.
//

import SwiftUI

@main
struct keychainApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            if session.isSignedIn {
                HomeView()
                    .environmentObject(session)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                SignInView()
                    .environmentObject(session)
                    .transition(.opacity)
            }
        }
    }
}
