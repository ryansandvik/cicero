//
//  GroupDetailView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    @StateObject var viewModel: GroupViewModel
    var group: Group
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showGroupSettings = false
    @Environment(\.presentationMode) var presentationMode

    init(group: Group) {
        self.group = group
        _viewModel = StateObject(wrappedValue: GroupViewModel(groupId: group.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Group Image
            Button(action: {
                // Navigate to GroupSettingsView
                showGroupSettings = true
            }) {
                if let imageURL = viewModel.imageURL, let url = URL(string: imageURL) {
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
                    // No image URL, show placeholder
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
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .center)

            // Group Title
            Button(action: {
                // Navigate to GroupSettingsView
                showGroupSettings = true
            }) {
                Text(viewModel.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)

            // Group Description
            Text(viewModel.description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Short Group ID with Copy Functionality
            HStack {
                Text("Group ID:")
                    .font(.headline)
                Spacer()
                Button(action: {
                    viewModel.copyGroupID()
                }) {
                    Text(shortGroupID())
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.horizontal)

            Divider()

            // Members List
            Text("Members")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.members.isEmpty {
                // Display a message or a loading indicator
                if viewModel.errorMessage.isEmpty {
                    ProgressView("Loading members...")
                        .padding()
                } else {
                    Text("No members found.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                List(viewModel.members) { member in
                    UserRowView(user: member)
                }
                .listStyle(PlainListStyle())
            }

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: groupNavigationBarContent)
        .sheet(isPresented: $showGroupSettings) {
            GroupSettingsView(viewModel: viewModel, group: group)
        }
        .alert(isPresented: $viewModel.showingError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    var groupNavigationBarContent: some View {
        Button(action: {
            // Navigate to GroupSettingsView
            showGroupSettings = true
        }) {
            Image(systemName: "gear")
                .imageScale(.large)
        }
    }

    // MARK: - Functions

    func shortGroupID() -> String {
        // Assuming group.id is a UUID or similar, we can shorten it by taking the first 8 characters
        return String(group.id.prefix(8))
    }
}
