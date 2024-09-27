//
//  Member.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import Foundation
import Firebase

struct Member: Identifiable {
    var id: String // Unique identifier, e.g., "\(groupId)_\(userId)"
    var userId: String
    var groupId: String
    var role: String // e.g., "admin", "member"
    var joinedAt: Date
    
    init(id: String, userId: String, groupId: String, role: String, joinedAt: Date) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.role = role
        self.joinedAt = joinedAt
    }
    
    init?(document: [String: Any], groupId: String) {
        guard let userId = document["userId"] as? String,
              let role = document["role"] as? String,
              let joinedAtTimestamp = document["joinedAt"] as? Timestamp else {
            return nil
        }
        
        self.userId = userId
        self.groupId = groupId
        self.role = role
        self.joinedAt = joinedAtTimestamp.dateValue()
        self.id = "\(groupId)_\(userId)"
    }
}
