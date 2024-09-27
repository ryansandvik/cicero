//
//  CreateGroupView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Views/Groups/CreateGroupView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateGroupView: View {
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 20) {
            TextField("Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Description", text: $groupDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: createGroup) {
                Text("Create Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Create Group")
    }

    func createGroup() {
        guard !groupName.isEmpty else {
            errorMessage = "Please enter a group name."
            showingError = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        let groupId = UUID().uuidString // Generate a unique ID for the group

        let group = Group(
            id: groupId,
            name: groupName,
            description: groupDescription,
            ownerId: userId,
            createdAt: Date()
        )

        do {
            try db.collection("groups").document(groupId).setData(from: group) { error in
                if let error = error {
                    errorMessage = "Failed to create group: \(error.localizedDescription)"
                    showingError = true
                } else {
                    // Add the creator to the group's members subcollection
                    let member = Member(userId: userId, role: "admin")
                    do {
                        try db.collection("groups").document(groupId)
                            .collection("members").document(userId)
                            .setData(from: member) { error in
                                if let error = error {
                                    errorMessage = "Failed to add member: \(error.localizedDescription)"
                                    showingError = true
                                } else {
                                    showingError = false
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                    } catch {
                        errorMessage = "Error adding member: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        } catch {
            errorMessage = "Error creating group: \(error.localizedDescription)"
            showingError = true
        }
    }
}

