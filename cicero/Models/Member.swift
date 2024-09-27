//
//  Member.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//


// Models/MemberModel.swift

import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String? // User ID
    var userId: String
    var role: String // 'member' or 'admin'
}
