//
//  GroupViewModel.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/27/24.
//


// GroupViewModel.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class GroupViewModel: ObservableObject {
    // Published properties to update the UI
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var ownerId: String = ""
    @Published var imageURL: String?
    @Published var createdAt: Date = Date()
    @Published var originalId: String?
    @Published var members: [User] = []
    
    // Additional Published properties for error handling
    @Published var errorMessage: String = ""
    @Published var showingError: Bool = false
    
    // Private properties
    private var userFetcher = UserFetcher()
    private var listener: ListenerRegistration?
    private var groupId: String
    
    // Initializer
    init(groupId: String) {
        self.groupId = groupId
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    // Function to start listening to Firestore updates
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated."
                self.showingError = true
            }
            return
        }
        
        let db = Firestore.firestore()
        listener = db.collection("groups").document(groupId).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch group details: \(error.localizedDescription)"
                    self.showingError = true
                }
                print("Error fetching group details: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "Group does not exist."
                    self.showingError = true
                }
                print("Group document does not exist.")
                return
            }
            
            let data = document.data()
            DispatchQueue.main.async {
                self.name = data?["name"] as? String ?? "No Name"
                self.description = data?["description"] as? String ?? "No Description"
                self.ownerId = data?["ownerId"] as? String ?? ""
                if let timestamp = data?["createdAt"] as? Timestamp {
                    self.createdAt = timestamp.dateValue()
                }
                self.imageURL = data?["imageURL"] as? String
                self.originalId = data?["originalId"] as? String
            }
            
            // Fetch members
            if let membersDict = data?["members"] as? [String: Bool] {
                let memberIds = Array(membersDict.keys)
                self.userFetcher.fetchUsers(uids: memberIds) { fetchedUsers in
                    DispatchQueue.main.async {
                        self.members = fetchedUsers
                    }
                }
            }
        }
    }
    
    // Function to stop listening to Firestore updates
    func stopListening() {
        listener?.remove()
    }
    
    // Function to copy Group ID to clipboard
    func copyGroupID() {
        UIPasteboard.general.string = groupId
        DispatchQueue.main.async {
            self.errorMessage = "Group ID copied to clipboard."
            self.showingError = true
        }
    }
}
