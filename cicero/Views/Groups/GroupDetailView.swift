//
//  GroupDetailView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Views/Groups/GroupDetailView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    var group: Group
    @State private var members: [String] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode

    @State private var showGroupSettings = false

        var body: some View {
            VStack {
                // Group Image
                Button(action: {
                    // Navigate to GroupSettingsView
                    showGroupSettings = true
                }) {
                    if let imageURL = group.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(50)
                            } else if phase.error != nil {
                                // Error loading image
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white)
                                    )
                            } else {
                                // Placeholder while loading
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                    } else {
                        // No image URL, show placeholder
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Group Name
                Button(action: {
                    // Navigate to GroupSettingsView
                    showGroupSettings = true
                }) {
                    Text(group.name)
                        .font(.title)
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())

                // Rest of your view content (e.g., list of members)
                List(members, id: \.self) { memberId in
                    Text(memberId) // Replace with user names if available
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: groupNavigationBarContent)
            .onAppear(perform: startListening)
            .onDisappear(perform: stopListening)
            .sheet(isPresented: $showGroupSettings) {
                GroupSettingsView(group: group)
            }
        }
    var groupNavigationBarContent: some View {
           HStack(spacing: 8) {
               // Back button is automatically provided by NavigationView
               // Group Image
               Button(action: {
                   // Navigate to GroupSettingsView
                   showGroupSettings = true
               }) {
                   if let imageURL = group.imageURL, let url = URL(string: imageURL) {
                       AsyncImage(url: url) { phase in
                           if let image = phase.image {
                               image
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: 32, height: 32)
                                   .clipped()
                                   .cornerRadius(16)
                           } else if phase.error != nil {
                               // Error loading image
                               Image(systemName: "photo")
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: 32, height: 32)
                                   .clipped()
                                   .cornerRadius(16)
                           } else {
                               // Placeholder while loading
                               ProgressView()
                                   .frame(width: 32, height: 32)
                           }
                       }
                   } else {
                       // No image URL, show placeholder
                       Circle()
                           .fill(Color.gray.opacity(0.5))
                           .frame(width: 32, height: 32)
                           .overlay(
                               Image(systemName: "photo")
                                   .foregroundColor(.white)
                           )
                   }
               }
               .buttonStyle(PlainButtonStyle())

               // Group Name
               Button(action: {
                   // Navigate to GroupSettingsView
                   showGroupSettings = true
               }) {
                   Text(group.name)
                       .font(.headline)
                       .foregroundColor(.primary)
               }
               .buttonStyle(PlainButtonStyle())
           }
       }

    func startListening() {
        // Real-time listener for members
    }

    func stopListening() {
        listener?.remove()
    }
}

