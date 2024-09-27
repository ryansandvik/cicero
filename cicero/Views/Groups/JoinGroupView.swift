//
//  JoinGroupView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Views/Groups/JoinGroupView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JoinGroupView: View {
    @State private var groupId = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 20) {
            TextField("Group ID or Invitation Code", text: $groupId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: joinGroup) {
                Text("Join Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
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
        .navigationTitle("Join Group")
    }

    func joinGroup() {
        guard !groupId.isEmpty else {
            errorMessage = "Please enter a group ID."
            showingError = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupId)

        groupRef.getDocument { document, error in
            if let document = document, document.exists {
                let member = Member(userId: userId, role: "member")
                do {
                    try groupRef.collection("members").document(userId)
                        .setData(from: member) { error in
                            if let error = error {
                                errorMessage = "Failed to join group: \(error.localizedDescription)"
                                showingError = true
                            } else {
                                showingError = false
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                } catch {
                    errorMessage = "Error joining group: \(error.localizedDescription)"
                    showingError = true
                }
            } else {
                errorMessage = "Group not found. Please check the ID."
                showingError = true
            }
        }
    }
}

