//
//  MyGroupsView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyGroupsView: View {
    @State private var groups: [Group] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingCreateGroup = false
    @State private var showJoinGroupView = false
    @ObservedObject var userFetcher = UserFetcher()

    var body: some View {
        NavigationView {
            VStack {
                // Create Group Banner Button
                Button(action: {
                    showingCreateGroup = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Create New Group")
                            .font(.headline)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()

                // Groups List
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
                                        Circle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.white)
                                            )
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
                            
                            // Group Name and Short ID
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text(shortGroupID(group.id))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Optional: Uncomment if you want the button at the bottom as well
                /*
                Button(action: {
                    showingCreateGroup = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Create New Group")
                            .font(.headline)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
                */
            }
            .navigationTitle("My Groups")
            .navigationBarItems(
                leading: EmptyView(),
                trailing:
                    HStack {
                        Button(action: {
                            // Navigate to JoinGroupView
                            showJoinGroupView = true
                        }) {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                        }
                        .sheet(isPresented: $showJoinGroupView) {
                            JoinGroupView()
                        }
                    }
            )
            .onAppear(perform: startListening)
            .onDisappear(perform: stopListening)
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
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
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    showingError = true
                    print("Error fetching groups: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No groups found.")
                    self.groups = []
                    return
                }

                self.groups = documents.compactMap { doc in
                    Group(document: doc.data(), id: doc.documentID)
                }
            }
    }

    func stopListening() {
        listener?.remove()
    }

    // MARK: - Clipboard Functionality

    func shortGroupID(_ id: String) -> String {
        return String(id.prefix(8))
    }
}
