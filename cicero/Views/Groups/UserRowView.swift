//
//  UserRowView.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

import SwiftUI

struct UserRowView: View {
    var user: User
    
    var body: some View {
        HStack(spacing: 15) {
            // User Avatar
            if let profileImageURL = user.profileImageURL, let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(20)
                    } else if phase.error != nil {
                        // Error loading image
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .foregroundColor(.white)
                            )
                    } else {
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: 40, height: 40)
                    }
                }
            } else {
                // No image URL, show placeholder
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.white)
                    )
            }
            
            // User Details
            VStack(alignment: .leading, spacing: 5) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}
