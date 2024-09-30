//
//  ciceroApp.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// ciceroApp.swift

import SwiftUI
import FirebaseAuth
import FirebaseAppCheck

@main
struct CiceroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var session = SessionStore()

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


