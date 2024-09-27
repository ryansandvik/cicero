//
//  GroupDetailView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    @ObservedObject var userFetcher = UserFetcher()
    var group: Group
    @State private var members: [User] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showGroupSettings = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(75)
                        } else if phase.error != nil {
                            // Error loading image
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                        } else {
                            // Placeholder while loading
                            ProgressView()
                                .frame(width: 150, height: 150)
                        }
                    }
                } else {
                    // No image URL, show placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .center)

            // Group Title
            Button(action: {
                // Navigate to GroupSettingsView
                showGroupSettings = true
            }) {
                Text(group.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)

            // Group Description
            Text(group.description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Short Group ID with Copy Functionality
            HStack {
                Text("Group ID:")
                    .font(.headline)
                Spacer()
                Button(action: {
                    copyGroupID()
                }) {
                    Text(shortGroupID())
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.horizontal)

            Divider()

            // Members List
            Text("Members")
                .font(.headline)
                .padding(.horizontal)

            List(members) { member in
                UserRowView(user: member)
            }
            .listStyle(PlainListStyle())

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: groupNavigationBarContent)
        .onAppear(perform: startListening)
        .onDisappear(perform: stopListening)
        .sheet(isPresented: $showGroupSettings) {
            GroupSettingsView(group: group)
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    var groupNavigationBarContent: some View {
        Button(action: {
            // Navigate to GroupSettingsView
            showGroupSettings = true
        }) {
            Image(systemName: "gear")
                .imageScale(.large)
        }
    }

    // MARK: - Functions

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        listener = db.collection("groups").document(group.id).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                errorMessage = "Failed to fetch group details: \(error.localizedDescription)"
                showingError = true
                print("Error fetching group details: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, document.exists else {
                errorMessage = "Group does not exist."
                showingError = true
                print("Group document does not exist.")
                return
            }

            let data = document.data()
            let name = data?["name"] as? String ?? "No Name"
            let description = data?["description"] as? String ?? "No Description"
            let ownerId = data?["ownerId"] as? String ?? ""
            let timestamp = data?["createdAt"] as? Timestamp
            let createdAt = timestamp?.dateValue() ?? Date()
            let imageURL = data?["imageURL"] as? String
            let originalId = data?["originalId"] as? String

            // Update local group data if necessary
            // Since `group` is not @State or @ObservedObject, consider making it mutable or using a ViewModel
            // For simplicity, we'll assume that the changes are reflected via the listener and fetching members

            // Fetch members
            if let membersDict = data?["members"] as? [String: Bool] {
                let memberIds = Array(membersDict.keys)
                userFetcher.fetchUsers(uids: memberIds) { fetchedUsers in
                    self.members = fetchedUsers
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
    }

    // MARK: - Clipboard Functionality

    func shortGroupID() -> String {
        // Assuming group.id is a UUID or similar, we can shorten it by taking the first 8 characters
        return String(group.id.prefix(8))
    }

    func copyGroupID() {
        UIPasteboard.general.string = group.id
        errorMessage = "Group ID copied to clipboard."
        showingError = true
    }
}
