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
    @State private var isCreatingGroup = false // Disable button when group is being created
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
                Text(isCreatingGroup ? "Creating..." : "Create Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCreatingGroup ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(isCreatingGroup) // Disable button while creating group

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

        isCreatingGroup = true // Disable the button

        let db = Firestore.firestore()
        let groupId = generateShortGroupId()

        let groupData: [String: Any] = [
            "name": groupName,
            "description": groupDescription,
            "ownerId": userId,
            "createdAt": Timestamp(),
            "originalId": userId
        ]

        db.collection("groups").document(groupId).setData(groupData) { error in
            if let error = error {
                errorMessage = "Failed to create group: \(error.localizedDescription)"
                showingError = true
                isCreatingGroup = false // Re-enable the button in case of error
            } else {
                addMember(to: groupId, userId: userId, role: "admin") { result in
                    switch result {
                    case .success():
                        if let image = selectedImage {
                            ImageUploader.uploadGroupImage(image: image, groupId: groupId) { uploadResult in
                                switch uploadResult {
                                case .success(let imageURL):
                                    db.collection("groups").document(groupId).updateData(["imageURL": imageURL]) { updateError in
                                        if let updateError = updateError {
                                            errorMessage = "Failed to upload image URL: \(updateError.localizedDescription)"
                                            showingError = true
                                        } else {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                        isCreatingGroup = false // Re-enable after success/failure
                                    }
                                case .failure(let uploadError):
                                    errorMessage = "Failed to upload image: \(uploadError.localizedDescription)"
                                    showingError = true
                                    isCreatingGroup = false // Re-enable the button
                                }
                            }
                        } else {
                            presentationMode.wrappedValue.dismiss()
                            isCreatingGroup = false // Re-enable after success
                        }
                    case .failure(let addError):
                        errorMessage = "Failed to add owner as member: \(addError.localizedDescription)"
                        showingError = true
                        isCreatingGroup = false // Re-enable the button
                    }
                }
            }
        }
    }

    func generateShortGroupId() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    func addMember(to groupId: String, userId: String, role: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let memberRef = db.collection("groups").document(groupId).collection("members").document(userId)

        memberRef.setData([
            "userId": userId,
            "role": role,
            "joinedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
