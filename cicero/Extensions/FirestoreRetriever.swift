//
//  FirestoreRetriever.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/28/24.
//

import FirebaseFirestore

extension Firestore {
    /// Fetches multiple documents based on their references.
    /// - Parameters:
    ///   - refs: An array of DocumentReferences to fetch.
    ///   - completion: Completion handler with fetched documents or an error.
    func getAllDocuments(refs: [DocumentReference], completion: @escaping ([DocumentSnapshot]?, Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var fetchedDocs: [DocumentSnapshot] = []
        var fetchError: Error? = nil

        for ref in refs {
            dispatchGroup.enter()
            ref.getDocument { snapshot, error in
                if let error = error {
                    fetchError = error
                } else if let snapshot = snapshot, snapshot.exists {
                    fetchedDocs.append(snapshot)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = fetchError {
                completion(nil, error)
            } else {
                completion(fetchedDocs, nil)
            }
        }
    }
}
