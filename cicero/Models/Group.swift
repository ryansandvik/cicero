//
//  Group.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import Foundation
import Firebase

struct Group: Identifiable {
    var id: String
    var name: String
    var description: String
    var ownerId: String
    var imageURL: String?
    var createdAt: Date
    var originalId: String?
    
    init(document: [String: Any], id: String) {
        self.id = id
        self.name = document["name"] as? String ?? "No Name"
        self.description = document["description"] as? String ?? "No Description"
        self.ownerId = document["ownerId"] as? String ?? ""
        self.imageURL = document["imageURL"] as? String
        if let timestamp = document["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        self.originalId = document["originalId"] as? String
    }
}

