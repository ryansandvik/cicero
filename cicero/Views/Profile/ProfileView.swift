//
//  ProfileView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/27/24.
//


// Views/ProfileView.swift

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var errorMessage = ""
    @State private var showingError = false
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 20) {
            if let user = Auth.auth().currentUser {
                Text("Hello, \(user.email ?? "User")!")
                    .font(.title)
                    .padding()

                Button(action: signOut) {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            } else {
                Text("Not signed in.")
            }

            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("Profile")
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // Update your session state or navigate to the login view
        } catch let signOutError as NSError {
            errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            showingError = true
        }
    }
}
