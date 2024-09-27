//
//  User.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import Foundation

struct User: Identifiable {
    var id: String // User UID from Firebase Auth
    var name: String
    var email: String
    var profileImageURL: String?
    
    // Additional user-related fields can be added here
    
    init(id: String, name: String, email: String, profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
    }
    
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let name = document["name"] as? String,
              let email = document["email"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = document["profileImageURL"] as? String
    }
}
