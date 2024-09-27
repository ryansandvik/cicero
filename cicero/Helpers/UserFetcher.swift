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
    
    /// Fetches user details for a list of UIDs.
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
        
        let group = DispatchGroup()
        var fetchedUsers: [User] = []
        var fetchError: Error?
        
        for uid in uids {
            group.enter()
            db.collection("users").document(uid).getDocument { document, error in
                defer { group.leave() }
                if let error = error {
                    fetchError = error
                    return
                }
                
                if let document = document, document.exists {
                    let data = document.data()
                    let name = data?["name"] as? String ?? "No Name"
                    let email = data?["email"] as? String ?? "No Email"
                    
                    let user = User(id: uid, name: name, email: email)
                    fetchedUsers.append(user)
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                print("Error fetching users: \(error.localizedDescription)")
                // Handle error appropriately, e.g., show an alert
            }
            self.users = fetchedUsers
            completion?(fetchedUsers)
        }
    }
}
