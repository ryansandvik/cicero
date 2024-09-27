//
//  PasswordField.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI

struct PasswordField: View {
    @State private var isPasswordVisible = false
    @Binding var password: String

    var body: some View {
        HStack {
            if isPasswordVisible {
                TextField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}
