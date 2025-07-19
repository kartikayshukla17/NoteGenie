//
//  AuthViewModel.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Firebase
import Combine

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isShowingAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    
    init() {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    // MARK: - Email Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch let error as NSError {
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
        isLoading = false
    }
    
    func createUser(withEmail email: String, password: String, fullname: String) async throws {
        isLoading = true
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update the display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullname
            try await changeRequest.commitChanges()
            
            self.userSession = result.user
            let user = User(id: result.user.uid, fullname: fullname, email: email, provider: "email")
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
        isLoading = false
    }
    
    // MARK: - Google Authentication
    func signInWithGoogle() async throws {
        isLoading = true
        
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isLoading = false
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get root view controller"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                isLoading = false
                throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            self.userSession = authResult.user
            
            // Save the user to Firestore if they don't exist
            let user = User(from: authResult.user)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser, merge: true)
            await fetchUser()
        } catch {
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
        isLoading = false
    }
    
    // MARK: - Common Methods
    func signOut() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            // Sign out from Google if needed
            GIDSignIn.sharedInstance.signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        Task {
            do {
                // Delete user data from Firestore
                try await Firestore.firestore().collection("users").document(user.uid).delete()
                // Delete the Firebase Auth account
                try await user.delete()
                self.userSession = nil
                self.currentUser = nil
            } catch {
                self.alertMessage = error.localizedDescription
                self.isShowingAlert = true
            }
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            if snapshot.exists {
                // If user exists in Firestore, use that data
                self.currentUser = try? snapshot.data(as: User.self)
            } else if let firebaseUser = Auth.auth().currentUser {
                // If not in Firestore but authenticated, create a new user entry
                let user = User(from: firebaseUser)
                let encodedUser = try Firestore.Encoder().encode(user)
                try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
                self.currentUser = user
            }
        } catch {
            self.alertMessage = "Failed to fetch user data: \(error.localizedDescription)"
            self.isShowingAlert = true
        }
    }
}
