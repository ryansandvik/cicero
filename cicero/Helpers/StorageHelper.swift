//
//  StorageHelper.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/27/24.
//


import UIKit
import FirebaseStorage

class StorageHelper {
    static let shared = StorageHelper()
    private let storageRef = Storage.storage().reference()

    private init() {}

    func uploadGroupImage(image: UIImage, groupId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: nil)))
            return
        }

        let imageRef = storageRef.child("groupImages/\(groupId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadURL = url {
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
    }
}
