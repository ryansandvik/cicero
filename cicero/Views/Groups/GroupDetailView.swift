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
    @State private var members: [Member] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showingError = false
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack {
            Text(group.name)
                .font(.largeTitle)
                .padding()

            Text(group.description)
                .font(.body)
                .padding()

            List(members) { member in
                Text(member.userId) // Replace with user display name if available
            }
        }
        .navigationTitle("Group Details")
        .navigationBarItems(trailing: leaveGroupButton())
        .onAppear(perform: fetchMembers)
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    func fetchMembers() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("groups").document(group.id ?? "")
            .collection("members")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                    showingError = true
                } else {
                    members = snapshot?.documents.compactMap { document in
                        try? document.data(as: Member.self)
                    } ?? []
                }
            }
    }

    func leaveGroup() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("groups").document(group.id ?? "")
            .collection("members").document(userId)
            .delete { error in
                if let error = error {
                    errorMessage = "Failed to leave group: \(error.localizedDescription)"
                    showingError = true
                } else {
                    // Navigate back to MyGroupsView
                    // You might need to adjust this based on your navigation setup
                }
            }
    }

    func leaveGroupButton() -> some View {
        Button(action: leaveGroup) {
            Text("Leave Group")
                .foregroundColor(.red)
        }
    }
}
