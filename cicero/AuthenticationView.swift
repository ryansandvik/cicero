//
//  AuthenticationView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


import SwiftUI

struct AuthenticationView: View {
    @State private var isLogin = true

    var body: some View {
        VStack {
            if isLogin {
                LoginView()
            } else {
                SignUpView()
            }

            Button(action: {
                isLogin.toggle()
            }) {
                Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                    .foregroundColor(.blue)
            }
            .padding()
        }
    }
}
