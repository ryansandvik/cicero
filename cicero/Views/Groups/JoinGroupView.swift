//
//  JoinGroupView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JoinGroupView: View {
    @State private var groupIdInput: String = ""
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false
    @State private var isLoading: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the Group ID to Join")
                .font(.headline)
                .padding(.top, 40)

            TextField("Group ID", text: $groupIdInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: joinGroup) {
                Text("Join Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView("Joining Group...")
                    .padding()
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

        isLoading = true

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(trimmedGroupId)

        // Fetch the group document to verify existence and current membership
        groupRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to find group: \(error.localizedDescription)"
                showingError = true
                print("Error fetching group: \(error.localizedDescription)")
                isLoading = false
                return
            }

            guard let document = document, document.exists else {
                errorMessage = "Group not found. Please check the ID."
                showingError = true
                print("Group with ID \(trimmedGroupId) does not exist.")
                isLoading = false
                return
            }

            // Check if the user is already a member
            if let membersDict = document.data()?["members"] as? [String: Bool],
               let userId = Auth.auth().currentUser?.uid,
               membersDict[userId] == true {
                errorMessage = "You are already a member of this group."
                showingError = true
                print("User \(userId) is already a member of group \(trimmedGroupId).")
                isLoading = false
                return
            }

            // Add the user to the group's members
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User not authenticated."
                showingError = true
                print("User is not authenticated.")
                isLoading = false
                return
            }

            // Update the 'members.{userId}' field to true
            groupRef.updateData([
                "members.\(userId)": true
            ]) { error in
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to join group: \(error.localizedDescription)"
                    showingError = true
                    print("Error joining group: \(error.localizedDescription)")
                } else {
                    print("User \(userId) successfully joined group \(trimmedGroupId).")
                    // Optionally, show a success message before dismissing
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
