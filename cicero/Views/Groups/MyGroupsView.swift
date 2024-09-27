//
//  MyGroupsView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Views/Groups/MyGroupsView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyGroupsView: View {
    @State private var groups: [Group] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showCreateGroupView = false
    @State private var showJoinGroupView = false

    var body: some View {
        NavigationView {
            VStack {
                List(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        HStack {
                            // Group Image
                            if let imageURL = group.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                            .cornerRadius(25)
                                    } else if phase.error != nil {
                                        // Error loading image
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                            .cornerRadius(25)
                                    } else {
                                        // Placeholder while loading
                                        ProgressView()
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            } else {
                                // No image URL, show placeholder
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white)
                                    )
                            }

                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text(group.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Create Group Button at the bottom
                Button(action: {
                    // Navigate to CreateGroupView
                    showCreateGroupView = true
                }) {
                    Text("Create a new group")
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20) // Adjust bottom padding
                .sheet(isPresented: $showCreateGroupView) {
                    CreateGroupView()
                }
            }
            .navigationBarTitle("My Groups", displayMode: .inline)
            .navigationBarItems(
                leading: EmptyView(),
                trailing:
                    HStack {
                        Button(action: {
                            // Navigate to JoinGroupView
                            showJoinGroupView = true
                        }) {
                            Image(systemName: "person.badge.plus")
                        }
                        .sheet(isPresented: $showJoinGroupView) {
                            JoinGroupView()
                        }
                    }
            )
            .onAppear(perform: startListening)
            .onDisappear(perform: stopListening)
            .alert(isPresented: $showingError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
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
        listener = db.collection("groups")
            .whereField("members.\(userId)", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    showingError = true
                } else if let snapshot = snapshot {
                    self.groups = snapshot.documents.compactMap { document in
                        let data = document.data()
                        let groupId = document.documentID
                        let name = data["name"] as? String ?? ""
                        let description = data["description"] as? String ?? ""
                        let ownerId = data["ownerId"] as? String ?? ""
                        let timestamp = data["createdAt"] as? Timestamp
                        let createdAt = timestamp?.dateValue() ?? Date()
                        let imageURL = data["imageURL"] as? String
                        let originalId = data["originalId"] as? String

                        // Append a timestamp to the imageURL to force update (cache busting)
                        let updatedImageURL = imageURL != nil ? "\(imageURL!)?v=\(Int(Date().timeIntervalSince1970))" : nil

                        return Group(
                            id: groupId,
                            name: name,
                            description: description,
                            ownerId: ownerId,
                            createdAt: createdAt,
                            imageURL: updatedImageURL,
                            originalId: originalId
                        )
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
    }
}
