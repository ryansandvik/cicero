//
//  GroupSettingsView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct GroupSettingsView: View {
    @State var group: Group
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingTransferOwnership = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userFetcher = UserFetcher()
    @State private var listener: ListenerRegistration? // Declare the listener

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
                } else if let imageURL = group.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(75)
                        } else if phase.error != nil {
                            // Error loading image
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                        } else {
                            // Placeholder while loading
                            ProgressView()
                                .frame(width: 150, height: 150)
                        }
                    }
                } else {
                    // No image selected or imageURL
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
            TextField("Group Name", text: $group.name, onCommit: {
                updateGroupName()
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Group Description
            TextField("Group Description", text: $group.description, onCommit: {
                updateGroupDescription()
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Short Group ID with Copy Functionality
            HStack {
                Text("Group ID:")
                    .font(.headline)
                Spacer()
                Button(action: {
                    copyGroupID()
                }) {
                    Text(shortGroupID())
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.horizontal)

            Spacer()

            // Leave Group Button
            Button(action: leaveGroup) {
                Text("Leave Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            // Transfer Ownership (if admin)
            if isAdmin() {
                Button(action: {
                    showingTransferOwnership = true
                }) {
                    Text("Transfer Ownership")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                // Delete Group Button
                Button(action: deleteGroup) {
                    Text("Delete Group")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }

            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Group Settings")
        .onAppear(perform: startListening)
        .onDisappear(perform: stopListening) // Ensure listener is removed when view disappears
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        uploadGroupImage()
                    }
                }
        }
        .actionSheet(isPresented: $showingTransferOwnership) {
            ActionSheet(title: Text("Transfer Ownership"), message: Text("Select a member"), buttons: transferOwnershipButtons())
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Notification"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Functions

    func isAdmin() -> Bool {
        return group.ownerId == Auth.auth().currentUser?.uid
    }

    func updateGroupName() {
        let trimmedName = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Group name cannot be empty."
            showingError = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).updateData(["name": trimmedName]) { error in
            if let error = error {
                errorMessage = "Failed to update group name: \(error.localizedDescription)"
                showingError = true
            } else {
                errorMessage = "Group name updated successfully."
                showingError = true
            }
        }
    }

    func updateGroupDescription() {
        let trimmedDescription = group.description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Group description cannot be empty."
            showingError = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).updateData(["description": trimmedDescription]) { error in
            if let error = error {
                errorMessage = "Failed to update group description: \(error.localizedDescription)"
                showingError = true
            } else {
                errorMessage = "Group description updated successfully."
                showingError = true
            }
        }
    }

    func uploadGroupImage() {
        guard let image = selectedImage, !group.id.isEmpty else { return }

        ImageUploader.uploadGroupImage(image: image, groupId: group.id) { result in
            switch result {
            case .success(let imageURL):
                updateGroupImageURL(imageURL)
            case .failure(let error):
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    func updateGroupImageURL(_ imageURL: String) {
        let db = Firestore.firestore()
        let timestamp = Int(Date().timeIntervalSince1970)
        let imageURLWithTimestamp = "\(imageURL)?v=\(timestamp)"
        
        db.collection("groups").document(group.id).updateData(["imageURL": imageURLWithTimestamp]) { error in
            if let error = error {
                errorMessage = "Failed to update group image: \(error.localizedDescription)"
                showingError = true
            } else {
                group.imageURL = imageURLWithTimestamp
                errorMessage = "Group image updated successfully."
                showingError = true
            }
        }
    }

    func leaveGroup() {
        guard let userId = Auth.auth().currentUser?.uid, !group.id.isEmpty else { return }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)

        groupRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to leave group: \(error.localizedDescription)"
                showingError = true
            } else if let document = document, document.exists {
                let membersDict = document.data()?["members"] as? [String: Bool] ?? [:]
                if membersDict.count == 1, membersDict.keys.contains(userId) {
                    // Only member left; delete the group
                    deleteGroup()
                } else {
                    // Remove user from group's members
                    groupRef.updateData([
                        "members.\(userId)": FieldValue.delete()
                    ]) { error in
                        if let error = error {
                            errorMessage = "Failed to leave group: \(error.localizedDescription)"
                            showingError = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }

    func deleteGroup() {
        guard !group.id.isEmpty else { return }
        let db = Firestore.firestore()
        let storageRef = Storage.storage().reference().child("groupImages/\(group.id).jpg")

        // Delete the group image from storage
        storageRef.delete { error in
            if let error = error {
                print("Failed to delete group image: \(error.localizedDescription)")
                // Continue with group deletion even if image deletion fails
            }
        }

        // Delete the group document
        db.collection("groups").document(group.id).delete { error in
            if let error = error {
                errorMessage = "Failed to delete group: \(error.localizedDescription)"
                showingError = true
            } else {
                // Optionally, delete any other associated data
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    func fetchMembers() {
        // Since members are now managed in GroupDetailView, this function can be removed or repurposed.
        // For now, it's empty.
    }

    func transferOwnershipButtons() -> [ActionSheet.Button] {
        // Since members are no longer managed here, you need to pass the new owner ID from GroupDetailView
        // Alternatively, remove this functionality from GroupSettingsView
        // For this example, we'll keep it but require the new owner ID to be passed differently
        return [.cancel()]
    }

    func transferOwnership(to newOwnerId: String) {
        guard !group.id.isEmpty else { return }
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).updateData([
            "ownerId": newOwnerId
        ]) { error in
            if let error = error {
                errorMessage = "Failed to transfer ownership: \(error.localizedDescription)"
                showingError = true
            } else {
                group.ownerId = newOwnerId
                errorMessage = "Ownership transferred successfully."
                showingError = true
            }
        }
    }

    // MARK: - Clipboard Functionality

    func shortGroupID() -> String {
        // Assuming group.id is a UUID or similar, we can shorten it by taking the first 8 characters
        return String(group.id.prefix(8))
    }

    func copyGroupID() {
        UIPasteboard.general.string = group.id
        errorMessage = "Group ID copied to clipboard."
        showingError = true
    }

    // MARK: - Firestore Listener Management

    func startListening() {
        let db = Firestore.firestore()
        listener = db.collection("groups").document(group.id).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                errorMessage = "Failed to fetch group details: \(error.localizedDescription)"
                showingError = true
                print("Error fetching group details: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, document.exists else {
                errorMessage = "Group does not exist."
                showingError = true
                print("Group document does not exist.")
                return
            }

            let data = document.data()
            let name = data?["name"] as? String ?? "No Name"
            let description = data?["description"] as? String ?? "No Description"
            let ownerId = data?["ownerId"] as? String ?? ""
            let timestamp = data?["createdAt"] as? Timestamp
            let createdAt = timestamp?.dateValue() ?? Date()
            let imageURL = data?["imageURL"] as? String
            let originalId = data?["originalId"] as? String

            // Update the group with new data
            group.name = name
            group.description = description
            group.ownerId = ownerId
            group.createdAt = createdAt
            group.imageURL = imageURL
            group.originalId = originalId
        }
    }

    func stopListening() {
        listener?.remove()
    }
}

