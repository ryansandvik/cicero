//
//  LoginView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: login) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: resetPassword) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
            }

            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    func login() {
        // Input validation
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            showingError = true
            return
        }

        // Sign in with Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            } else {
                // Navigate to the main app interface
            }
        }
    }


    func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to reset password."
            showingError = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            } else {
                errorMessage = "A password reset email has been sent."
                showingError = true
            }
        }
    }

}
