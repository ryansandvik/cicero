//
//  ciceroApp.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct CiceroApp: App {
    @StateObject var session = SessionStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if session.isLoggedIn {
                // Main app interface
                ContentView()
                    .environmentObject(session)
            } else {
                // Show authentication flow
                AuthenticationView()
                    .environmentObject(session)
            }
        }
    }
}

