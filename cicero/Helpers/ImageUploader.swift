//
//  ImageUploader.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/27/24.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore

struct ImageUploader {
    
    /// Uploads a group image to Firebase Storage after resizing it.
    /// - Parameters:
    ///   - image: The original UIImage selected by the user.
    ///   - groupId: The unique identifier for the group.
    ///   - completion: A closure that returns a Result containing the download URL string or an Error.
    static func uploadGroupImage(image: UIImage, groupId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Step 1: Resize the image
        guard let resizedImage = image.resizeImage(to: CGSize(width: 500, height: 500)) else {
            let error = NSError(domain: "ImageResizeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image."])
            completion(.failure(error))
            return
        }
        
        // Step 2: Convert the image to JPEG data
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.75) else {
            let error = NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
            completion(.failure(error))
            return
        }
        
        // Step 3: Create a reference to Firebase Storage
        let storageRef = Storage.storage().reference().child("groupImages/\(groupId).jpg")
        
        // Step 4: Define metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Step 5: Upload the image data
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Step 6: Retrieve the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let downloadURL = url {
                    completion(.success(downloadURL.absoluteString))
                } else {
                    let error = NSError(domain: "DownloadURLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve download URL."])
                    completion(.failure(error))
                }
            }
        }
    }
}

extension UIImage {
    /// Resizes the image to the specified target size.
    /// - Parameter targetSize: The desired size to resize the image to.
    /// - Returns: A new UIImage resized to the target size, or nil if resizing fails.
    func resizeImage(to targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine the scale factor to maintain aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)

        // Compute the new image size
        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        // Draw the image in the scaled size
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: scaledSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
