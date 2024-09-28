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
        let groupData: [String: Any] = [
            "name": groupName,
            "description": groupDescription,
            "ownerId": userId,
            "createdAt": Timestamp(),
            "originalId": userId, // Assuming originalId is similar to ownerId
            // Remove the 'members' map
        ]

        // Save the group data to Firestore
        db.collection("groups").document(groupId).setData(groupData) { error in
            if let error = error {
                errorMessage = "Failed to create group: \(error.localizedDescription)"
                showingError = true
            } else {
                // Now add the owner as an admin in the members subcollection
                addMember(to: groupId, userId: userId, role: "admin") { result in
                    switch result {
                    case .success():
                        // Now upload the image if selected
                        if let image = selectedImage {
                            ImageUploader.uploadGroupImage(image: image, groupId: groupId) { uploadResult in
                                switch uploadResult {
                                case .success(let imageURL):
                                    // Update the group document with the imageURL
                                    db.collection("groups").document(groupId).updateData(["imageURL": imageURL]) { updateError in
                                        if let updateError = updateError {
                                            errorMessage = "Failed to upload image URL: \(updateError.localizedDescription)"
                                            showingError = true
                                        } else {
                                            // Successfully created group with image
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                case .failure(let uploadError):
                                    errorMessage = "Failed to upload image: \(uploadError.localizedDescription)"
                                    showingError = true
                                }
                            }
                        } else {
                            // No image selected, dismiss view
                            presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let addError):
                        errorMessage = "Failed to add owner as member: \(addError.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
    }

    func generateShortGroupId() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    /// Adds a member to the group's members subcollection
    /// - Parameters:
    ///   - groupId: The ID of the group
    ///   - userId: The ID of the user to add
    ///   - role: The role of the user (e.g., "admin", "member")
    ///   - completion: Completion handler with success or failure
    func addMember(to groupId: String, userId: String, role: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let memberRef = db.collection("groups").document(groupId).collection("members").document(userId)

        memberRef.setData([
            "role": role,
            "joinedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error adding member: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Member \(userId) added successfully to group \(groupId).")
                completion(.success(()))
            }
        }
    }
}
