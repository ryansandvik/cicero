//
//  ContentView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        TabView {
            MyGroupsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }

            ProfileView() // Create this view to display user profile and sign out
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

