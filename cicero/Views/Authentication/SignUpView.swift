//
//  SignUpView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SignUpView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Using PasswordField for password input
            PasswordField(password: $password)

            // Using PasswordField for confirm password input
            PasswordField(password: $confirmPassword)

            Button(action: signUp) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // Function to handle sign-up
    func signUp() {
        // Input validation
        guard !fullName.isEmpty else {
            errorMessage = "Please enter your full name."
            showingError = true
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            showingError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showingError = true
            return
        }
        
        // Create user with Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                // Use custom error messages from AuthErrorHelper
                errorMessage = customErrorMessage(for: error)
                showingError = true
            } else {
                // Store user data in Firestore after successful sign-up
                if let uid = authResult?.user.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).setData([
                        "fullName": fullName,
                        "email": email
                    ]) { error in
                        if let error = error as NSError? {
                            // Use custom error messages for Firestore errors as well (optional)
                            errorMessage = "User created but failed to save name: \(error.localizedDescription)"
                            showingError = true
                        } else {
                            // Handle successful Firestore write (e.g., navigate to main app interface)
                            showingError = false
                        }
                    }
                }
            }
        }
    }
}
