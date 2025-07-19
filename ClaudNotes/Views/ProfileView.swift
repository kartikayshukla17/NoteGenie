//
//  ProfileView.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Profile image or initials
                        ProfileImageView(
                            imageURL: authViewModel.currentUser?.avatarURL,
                            initials: authViewModel.currentUser?.initials ?? "U"
                        )
                        
                        VStack(spacing: 4) {
                            Text(authViewModel.currentUser?.fullname ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let provider = authViewModel.currentUser?.provider {
                                HStack(spacing: 4) {
                                    Image(systemName: provider == "google" ? "globe" : "envelope")
                                        .font(.caption)
                                    Text("Signed in with \(provider.capitalized)")
                                        .font(.caption)
                                }
                                .foregroundStyle(.tertiary)
                                .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile sections
                    VStack(spacing: 16) {
                        // Account section
                        ProfileSection(title: "Account") {
                            ProfileRow(
                                icon: "person.circle",
                                title: "Edit Profile",
                                subtitle: "Update your personal information"
                            ) {
                                // TODO: Navigate to edit profile
                            }
                            
                            ProfileRow(
                                icon: "bell",
                                title: "Notifications",
                                subtitle: "Manage your notification preferences"
                            ) {
                                // TODO: Navigate to notifications settings
                            }
                        }
                        
                        // Data section
                        ProfileSection(title: "Data & Privacy") {
                            ProfileRow(
                                icon: "icloud",
                                title: "Sync Settings",
                                subtitle: "Manage data synchronization"
                            ) {
                                // TODO: Navigate to sync settings
                            }
                            
                            ProfileRow(
                                icon: "square.and.arrow.down",
                                title: "Export Data",
                                subtitle: "Download your notes and data"
                            ) {
                                // TODO: Export functionality
                            }
                        }
                        
                        // Support section
                        ProfileSection(title: "Support") {
                            ProfileRow(
                                icon: "questionmark.circle",
                                title: "Help & Support",
                                subtitle: "Get help and contact support"
                            ) {
                                // TODO: Navigate to help
                            }
                            
                            ProfileRow(
                                icon: "star",
                                title: "Rate App",
                                subtitle: "Share your feedback on the App Store"
                            ) {
                                // TODO: Rate app functionality
                            }
                        }
                        
                        // Danger zone
                        ProfileSection(title: "Account Actions") {
                            ProfileRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                subtitle: "Sign out of your account",
                                isDestructive: false
                            ) {
                                showingSignOutAlert = true
                            }
                            
                            ProfileRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently delete your account and data",
                                isDestructive: true
                            ) {
                                showingDeleteAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                authViewModel.deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your notes and data will be permanently deleted.")
        }
    }
}

struct ProfileImageView: View {
    let imageURL: URL?
    let initials: String
    
    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .overlay {
                    Text(initials)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

struct ProfileAvatarView: View {
    let imageURL: URL?
    let initials: String
    let size: CGFloat
    
    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .overlay {
                    Text(initials)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.quaternary, lineWidth: 0.5)
        }
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : Color.accentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(isDestructive ? .red : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView(authViewModel: {
        let vm = AuthViewModel()
        vm.currentUser = User.MOCK_USER
        return vm
    }())
}
