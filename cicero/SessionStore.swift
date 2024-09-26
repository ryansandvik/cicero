//
//  SessionStore.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//
import SwiftUI
import FirebaseAuth

class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    var handle: AuthStateDidChangeListenerHandle?

    init() {
        listen()
    }

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
                self.isLoggedIn = true
            } else {
                self.isLoggedIn = false
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
