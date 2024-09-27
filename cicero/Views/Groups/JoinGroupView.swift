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
    @State private var groupIdInput: String = ""
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Group ID", text: $groupIdInput)
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

            Spacer()
        }
        .padding()
        .navigationTitle("Join Group")
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Functions

    func joinGroup() {
        let trimmedGroupId = groupIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedGroupId.isEmpty else {
            errorMessage = "Please enter a group ID."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(trimmedGroupId)

        groupRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to find group: \(error.localizedDescription)"
                showingError = true
                return
            }

            guard let document = document, document.exists else {
                errorMessage = "Group not found. Please check the ID."
                showingError = true
                return
            }

            // Check if the user is already a member
            if let membersDict = document.data()?["members"] as? [String: Bool],
               let userId = Auth.auth().currentUser?.uid,
               membersDict[userId] == true {
                errorMessage = "You are already a member of this group."
                showingError = true
                return
            }

            // Add the user to the group's members
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User not authenticated."
                showingError = true
                return
            }

            groupRef.updateData([
                "members.\(userId)": true
            ]) { error in
                if let error = error {
                    errorMessage = "Failed to join group: \(error.localizedDescription)"
                    showingError = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
