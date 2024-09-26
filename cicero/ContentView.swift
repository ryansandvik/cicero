//
//  ContentView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack {
            Text("Welcome to Cicero!")
                .font(.largeTitle)
                .padding()

            Button(action: {
                session.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
            .padding()
        }
    }
}
