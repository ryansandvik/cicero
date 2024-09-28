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
        var fetchErrors: [Error] = []
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
                        fetchErrors.append(error)
                        print("Error fetching users in batch \(batch): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        print("No snapshot returned for batch \(batch).")
                        return
                    }
                    
                    let usersInBatch = snapshot.documents.compactMap { doc -> User? in
                        let data = doc.data()
                        let name = data["fullName"] as? String ?? "No Name" // Updated to match your user data
                        let email = data["email"] as? String ?? "No Email"
                        let profileImageURL = data["profileImageURL"] as? String
                        return User(id: doc.documentID, name: name, email: email, profileImageURL: profileImageURL)
                    }
                    
                    fetchedUsers.append(contentsOf: usersInBatch)
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            if !fetchErrors.isEmpty {
                // Aggregate errors for better debugging
                let combinedError = fetchErrors.map { $0.localizedDescription }.joined(separator: "\n")
                print("Errors fetching users: \(combinedError)")
                // Optionally, you can pass the error messages back through completion or handle them as needed
            }
            self.users = fetchedUsers
            completion?(fetchedUsers)
        }
    }
}
