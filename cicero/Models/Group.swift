//
//  Group.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Models/GroupModel.swift

import Foundation
import FirebaseFirestore

struct Group: Identifiable, Codable {
    @DocumentID var id: String? // Group ID
    var name: String
    var description: String
    var ownerId: String
    var createdAt: Date
}
