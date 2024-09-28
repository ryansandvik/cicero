//
//  UserFetcher.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import Foundation
import FirebaseFirestore

class UserFetcher: ObservableObject {
    @Published var users: [User] = []
    
    private var db = Firestore.firestore()
    
    /// Fetches user details for a list of UIDs using batched 'whereIn' queries.
    /// - Parameters:
    ///   - uids: An array of user UIDs.
    ///   - completion: Optional completion handler with fetched users.
    func fetchUsers(uids: [String], completion: (([User]) -> Void)? = nil) {
        guard !uids.isEmpty else {
            DispatchQueue.main.async {
                self.users = []
                completion?([])
            }
            return
        }
        
        let batchSize = 10 // Firestore 'whereIn' limit
        var fetchedUsers: [User] = []
        var fetchError: Error?
        let dispatchGroup = DispatchGroup()
        
        // Split UIDs into batches of 10
        let uidBatches = stride(from: 0, to: uids.count, by: batchSize).map {
            Array(uids[$0..<min($0 + batchSize, uids.count)])
        }
        
        for batch in uidBatches {
            dispatchGroup.enter()
            db.collection("users")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments { [weak self] snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        fetchError = error
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    let usersInBatch = snapshot.documents.compactMap { doc -> User? in
                        let data = doc.data()
                        let name = data["name"] as? String ?? "No Name"
                        let email = data["email"] as? String ?? "No Email"
                        let profileImageURL = data["profileImageURL"] as? String
                        return User(id: doc.documentID, name: name, email: email, profileImageURL: profileImageURL)
                    }
                    
                    fetchedUsers.append(contentsOf: usersInBatch)
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = fetchError {
                print("Error fetching users: \(error.localizedDescription)")
                // Handle error appropriately, e.g., show an alert
            }
            self.users = fetchedUsers
            completion?(fetchedUsers)
        }
    }
}
