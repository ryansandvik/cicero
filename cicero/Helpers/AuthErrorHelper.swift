//
//  AuthErrorHelper.swift
//  cicero
//
//  Created by Ryan Sandvik on 9/26/24.
//

// AuthErrorHelper.swift

import FirebaseAuth

func customErrorMessage(for error: NSError) -> String {
    switch AuthErrorCode(rawValue: error.code) {
    case .invalidEmail:
        return "That email doesn't look quite right. Can you double-check it?"
    case .wrongPassword:
        return "Oops! That's not the correct password. Want to try again?"
    case .userNotFound:
        return "We couldn't find an account with that email. Want to sign up?"
    case .networkError:
        return "Looks like there's a network issue. Please check your connection."
    case .emailAlreadyInUse:
        return "This email is already in use! Maybe you signed up earlier?"
    case .weakPassword:
        return "That password looks too weak. Try something stronger!"
    default:
        return "Hmm, something went wrong. Could you try again?"
    }
}
