//
//  PurchaseCancellationClassifier.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// Recognises the various shapes of RevenueCat's "user cancelled the
/// purchase" error.
///
/// RevenueCat surfaces purchase cancellation either as a typed
/// `RevenueCat.ErrorCode` value or as an `NSError` whose `code` matches that
/// case's raw value, depending on entry point. This helper reduces both forms
/// to a single boolean.
public enum PurchaseCancellationClassifier {

    /// Returns `true` if the error represents the user dismissing the
    /// purchase sheet rather than a real failure.
    public static func isUserCancellation(_ error: Error) -> Bool {
        if let rcError = error as? RevenueCat.ErrorCode,
           rcError == .purchaseCancelledError {
            return true
        }
        let nsError = error as NSError
        if let code = RevenueCat.ErrorCode(rawValue: nsError.code),
           code == .purchaseCancelledError {
            return true
        }
        return false
    }
}
