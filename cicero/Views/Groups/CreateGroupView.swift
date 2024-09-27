//
//  CreateGroupView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

//
//  CreateGroupView.swift
//  YourAppName
//
//  Created by Your Name on Date.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateGroupView: View {
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            // Group Image
            Button(action: {
                showingImagePicker = true
            }) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(75)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Group Name
            TextField("Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Group Description
            TextField("Description", text: $groupDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Spacer()

            // Create Group Button
            Button(action: createGroup) {
                Text("Create Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Create Group")
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }

    func createGroup() {
        guard !groupName.isEmpty else {
            errorMessage = "Please enter a group name."
            showingError = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        let groupId = generateShortGroupId()

        // Create the group data without the imageURL initially
        var groupData: [String: Any] = [
            "name": groupName,
            "description": groupDescription,
            "ownerId": userId,
            "createdAt": Timestamp(),
            "members": [userId: true],
            "imageURL": "" // Placeholder; will update after image upload
        ]

        // Save the group data to Firestore
        db.collection("groups").document(groupId).setData(groupData) { error in
            if let error = error {
                errorMessage = "Failed to create group: \(error.localizedDescription)"
                showingError = true
            } else {
                // Now upload the image if selected
                if let image = selectedImage {
                    ImageUploader.uploadGroupImage(image: image, groupId: groupId) { result in
                        switch result {
                        case .success(let imageURL):
                            // Update the group document with the imageURL
                            db.collection("groups").document(groupId).updateData(["imageURL": imageURL]) { error in
                                if let error = error {
                                    errorMessage = "Failed to upload image URL: \(error.localizedDescription)"
                                    showingError = true
                                } else {
                                    // Successfully created group with image
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        case .failure(let error):
                            errorMessage = "Failed to upload image: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                } else {
                    // No image selected, dismiss view
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    func generateShortGroupId() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

