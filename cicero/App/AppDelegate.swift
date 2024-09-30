//
//  AppDelegate.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/30/24.
//


// AppDelegate.swift

import UIKit
import Firebase
import FirebaseAppCheck

@objc(AppDelegate)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize App Check with DeviceCheck provider
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Set Firebase logger level to debug for detailed logs (optional)
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        
        return true
    }
}

