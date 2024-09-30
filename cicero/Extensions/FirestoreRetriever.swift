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
        var errors: [Error] = []

        for ref in refs {
            dispatchGroup.enter()
            print("[FirestoreRetriever] Fetching document at path: \(ref.path)")
            ref.getDocument { snapshot, error in
                if let error = error {
                    print("[FirestoreRetriever] Error fetching document at \(ref.path): \(error.localizedDescription)")
                    errors.append(error)
                } else if let snapshot = snapshot, snapshot.exists {
                    print("[FirestoreRetriever] Successfully fetched document at \(ref.path)")
                    fetchedDocs.append(snapshot)
                } else {
                    print("[FirestoreRetriever] Document does not exist at \(ref.path)")
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if !errors.isEmpty {
                // Combine all error descriptions into a single error
                let combinedError = NSError(domain: "FirestoreErrors", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: errors.map { $0.localizedDescription }.joined(separator: "\n")
                ])
                print("[FirestoreRetriever] Combined Error: \(combinedError.localizedDescription)")
                completion(nil, combinedError)
            } else {
                print("[FirestoreRetriever] Successfully fetched all documents.")
                completion(fetchedDocs, nil)
            }
        }
    }
}
