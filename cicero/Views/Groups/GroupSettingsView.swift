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
import FirebaseFunctions

// MARK: - Debounce Function
   func debounce(_ delay: TimeInterval, action: @escaping () -> Void) -> () -> Void {
       var currentWorkItem: DispatchWorkItem?

       return {
           currentWorkItem?.cancel()
           currentWorkItem = DispatchWorkItem {
               action()
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
       }
   }

struct GroupSettingsView: View {
    @ObservedObject var viewModel: GroupViewModel
    @State var group: Group
    @State private var originalGroupName = "" // Store original group name
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingTransferOwnership = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var navigateToMyGroups = false
    @State private var showingDeleteConfirmation = false // For delete confirmation prompt
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userFetcher = UserFetcher()
    @State private var listener: ListenerRegistration?
    @State private var functions = Functions.functions() // Firebase Functions reference

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
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                        } else {
                            ProgressView()
                                .frame(width: 150, height: 150)
                        }
                    }
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

            // Group Name (debounced update)
            TextField("Group Name", text: $group.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: group.name) { newValue in
                    let debouncedUpdateName = debounce(0.5) {
                        // Only update if name is not empty
                        if !group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            updateGroupName()
                        }
                    }
                    debouncedUpdateName()
                }
                .alert(isPresented: $showingDeleteConfirmation) {
                    print("Delete confirmation alert should be showing") // This should print if the alert is being triggered
                    return Alert(
                        title: Text("Delete Group"),
                        message: Text("Are you sure you want to delete this group?"),
                        primaryButton: .destructive(Text("Delete")) {
                            print("Delete confirmed") // Confirms that the delete button in the alert is pressed
                            callDeleteGroupFunction()
                        },
                        secondaryButton: .cancel{
                            print("Delete canceled") // Confirms that the cancel button in the alert is pressed
                        }
                    )
                }

            // Group Description (debounced update, no empty validation)
            TextField("Group Description", text: $group.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: group.description) { newValue in
                    let debouncedUpdateDescription = debounce(0.5) {
                        updateGroupDescription()
                    }
                    debouncedUpdateDescription()
                }

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
                Button(action: {
                    print("Delete group button pressed")
                    showingDeleteConfirmation = true
                    print("Delete button pressed")
                }) {
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
        .onAppear {
            startListening()
            originalGroupName = group.name // Store original group name on view appear
        }
        .onDisappear {
            stopListening()
            // Revert group name if left blank
            if group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                group.name = originalGroupName
                updateGroupName() // Update Firestore with the original name
            }
        }
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
        .background(
            NavigationLink(destination: MyGroupsView(), isActive: $navigateToMyGroups) {
                EmptyView()
            }
        )
    }

    // MARK: - Functions
    
    func callDeleteGroupFunction() {
        let groupId = group.id

        // Call the Firebase Cloud Function to delete the group
        let functions = Functions.functions()
        functions.httpsCallable("deleteGroup").call(["groupId": groupId]) { result, error in
            if let error = error {
                errorMessage = "Failed to delete group: \(error.localizedDescription)"
                showingError = true
                return
            }

            // Successfully deleted group
            presentationMode.wrappedValue.dismiss()
        }
    }



    func isAdmin() -> Bool {
        return group.ownerId == Auth.auth().currentUser?.uid
    }

    func updateGroupName() {
            let db = Firestore.firestore()
            db.collection("groups").document(group.id).updateData(["name": group.name]) { error in
                if let error = error {
                    errorMessage = "Failed to update group name: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    
    func updateGroupDescription() {
            let db = Firestore.firestore()
            db.collection("groups").document(group.id).updateData(["description": group.description]) { error in
                if let error = error {
                    errorMessage = "Failed to update group description: \(error.localizedDescription)"
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
            let memberRef = groupRef.collection("members").document(userId)

            memberRef.getDocument { document, error in
                if let error = error {
                    errorMessage = "Failed to leave group: \(error.localizedDescription)"
                    showingError = true
                    return
                }

                if let document = document, document.exists {
                    // Check if the user is the owner
                    if group.ownerId == userId {
                        errorMessage = "Owner cannot leave the group. Transfer ownership before leaving."
                        showingError = true
                        return
                    }

                    // Remove user from group's members subcollection
                    memberRef.delete { error in
                        if let error = error {
                            errorMessage = "Failed to leave group: \(error.localizedDescription)"
                            showingError = true
                        } else {
                            navigateToMyGroups = true // Trigger navigation
                        }
                    }
                } else {
                    errorMessage = "You are not a member of this group."
                    showingError = true
                }
            }
        }


    func deleteGroup() {
            // Call the Firebase Cloud Function to delete the group
            functions.httpsCallable("deleteGroup").call(["groupId": group.id]) { result, error in
                if let error = error {
                    errorMessage = "Failed to delete group: \(error.localizedDescription)"
                    showingError = true
                } else {
                    // After successful deletion, navigate back to MyGroupsView
                    navigateToMyGroups = true
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

