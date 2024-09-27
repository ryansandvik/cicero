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
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showingError = false
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationView {
            List(groups) { group in
                NavigationLink(destination: GroupDetailView(group: group)) {
                    VStack(alignment: .leading) {
                        Text(group.name)
                            .font(.headline)
                        Text(group.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("My Groups")
            .navigationBarItems(
                leading: Button(action: fetchGroups) {
                    Image(systemName: "arrow.clockwise")
                },
                trailing:
                    HStack {
                        NavigationLink(destination: JoinGroupView()) {
                            Image(systemName: "person.badge.plus")
                        }
                        NavigationLink(destination: CreateGroupView()) {
                            Image(systemName: "plus")
                        }
                    }
            )
            .onAppear(perform: fetchGroups)
            .alert(isPresented: $showingError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func fetchGroups() {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("groups")
            .whereField("members.\(userId)", isEqualTo: true)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    showingError = true
                } else {
                    groups = snapshot?.documents.compactMap { document in
                        try? document.data(as: Group.self)
                    } ?? []
                }
            }
    }
}
