//
//  JoinGroupView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct JoinGroupView: View {
    @State private var groupIdInput: String = ""
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false
    @State private var isLoading: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the Group ID to Join")
                .font(.headline)
                .padding(.top, 40)
    
            TextField("Group ID", text: $groupIdInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)
    
            Button(action: joinGroup) {
                Text("Join Group")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(isLoading)
    
            if isLoading {
                ProgressView("Joining Group...")
                    .padding()
            }
    
            if showingError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
    
            Spacer()
        }
        .padding()
        .navigationTitle("Join Group")
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Functions
    
    func joinGroup() {
        let trimmedGroupId = groupIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedGroupId.isEmpty else {
            errorMessage = "Please enter a group ID."
            showingError = true
            return
        }
        
        isLoading = true
        
        // Initialize Firebase Functions within the function
        let functions = Functions.functions()
        
        // Call the 'joinGroup' Cloud Function
        functions.httpsCallable("joinGroup").call(["groupId": trimmedGroupId]) { result, error in
            isLoading = false
            
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.userInfo[FunctionsErrorDetailsKey] as? String ?? "An error occurred."
                    errorMessage = message
                } else {
                    errorMessage = error.localizedDescription
                }
                showingError = true
                print("Error joining group: \(error.localizedDescription)")
                return
            }
            
            // Handle success
            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool,
               success {
                print("Successfully joined the group.")
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Unexpected response from the server."
                showingError = true
                print("Unexpected response: \(String(describing: result?.data))")
            }
        }
    }
}
