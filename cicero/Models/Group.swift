//
//  Group.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import Foundation
import Firebase

struct Group: Identifiable, Equatable {
    var id: String // Group ID (Firestore Document ID)
    var name: String
    var description: String
    var ownerId: String
    var createdAt: Date
    var imageURL: String?
    var originalId: String?
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.description == rhs.description &&
            lhs.ownerId == rhs.ownerId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.imageURL == rhs.imageURL &&
            lhs.originalId == rhs.originalId
    }
    
    init(id: String, name: String, description: String, ownerId: String, createdAt: Date, imageURL: String? = nil, originalId: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.imageURL = imageURL
        self.originalId = originalId
    }
    
    init?(document: [String: Any], id: String) {
        guard let name = document["name"] as? String,
              let description = document["description"] as? String,
              let ownerId = document["ownerId"] as? String,
              let createdAtTimestamp = document["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.createdAt = createdAtTimestamp.dateValue()
        self.imageURL = document["imageURL"] as? String
        self.originalId = document["originalId"] as? String
    }
}
