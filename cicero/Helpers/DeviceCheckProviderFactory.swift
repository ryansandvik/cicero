//
//  DeviceCheckProviderFactory.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/29/24.
//

import FirebaseCore
import FirebaseAppCheck

// Factory to provide DeviceCheck as the App Check provider.
class DeviceCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return DeviceCheckProvider(app: app)  // Correct initialization of DeviceCheckProvider
    }
}
