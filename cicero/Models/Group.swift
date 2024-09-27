//
//  Group.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Models/GroupModel.swift

import Foundation
import FirebaseFirestore

struct Group: Identifiable, Equatable {
    var id: String? // Group ID (short ID)
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
}
