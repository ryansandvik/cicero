import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct GroupSettingsView: View {
    @State var group: Group
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingTransferOwnership = false
    @State private var members: [Member] = []
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
        .onAppear(perform: fetchMembers)
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
    }

    func isAdmin() -> Bool {
        return group.ownerId == Auth.auth().currentUser?.uid
    }

    func updateGroupName() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id ?? "").updateData(["name": group.name]) { error in
            if let error = error {
                errorMessage = "Failed to update group name: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    func uploadGroupImage() {
        guard let image = selectedImage, let groupId = group.id else { return }
        let storageRef = Storage.storage().reference().child("groupImages/\(groupId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                showingError = true
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    errorMessage = "Failed to retrieve image URL: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                if let url = url {
                    updateGroupImageURL(url.absoluteString)
                }
            }
        }
    }

    func updateGroupImageURL(_ imageURL: String) {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id ?? "").updateData(["imageURL": imageURL]) { error in
            if let error = error {
                errorMessage = "Failed to update group image: \(error.localizedDescription)"
                showingError = true
            } else {
                group.imageURL = imageURL
            }
        }
    }

    func leaveGroup() {
        guard let userId = Auth.auth().currentUser?.uid, let groupId = group.id else { return }

        if isAdmin() {
            errorMessage = "You must transfer ownership before leaving the group."
            showingError = true
            return
        }

        let db = Firestore.firestore()
        db.collection("groups").document(groupId).updateData([
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

    func fetchMembers() {
        guard let groupId = group.id else { return }
        let db = Firestore.firestore()
        db.collection("groups").document(groupId).getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                showingError = true
            } else if let document = document, document.exists {
                if let membersDict = document.data()?["members"] as? [String: Bool] {
                    self.members = membersDict.keys.map { userId in
                        return Member(id: userId, userId: userId, role: "member")
                    }
                }
            }
        }
    }

    func transferOwnershipButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        for member in members where member.userId != group.ownerId {
            buttons.append(.default(Text(member.userId)) {
                transferOwnership(to: member.userId)
            })
        }
        buttons.append(.cancel())
        return buttons
    }

    func transferOwnership(to newOwnerId: String) {
        guard let groupId = group.id else { return }
        let db = Firestore.firestore()
        db.collection("groups").document(groupId).updateData([
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
}