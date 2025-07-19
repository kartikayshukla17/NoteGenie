//
//  FirebaseConfig.swift
//  ClaudNotes
//
//  Created by Kiro on 19/07/25.
//

import Foundation
import Firebase
import GoogleSignIn

class FirebaseConfig {
    static func configure() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Warning: Could not find GoogleService-Info.plist or CLIENT_ID")
            return
        }
        
        let gidConfig = GIDConfiguration(clientID: clientId)
        
        GIDSignIn.sharedInstance.configuration = gidConfig
    }
}
