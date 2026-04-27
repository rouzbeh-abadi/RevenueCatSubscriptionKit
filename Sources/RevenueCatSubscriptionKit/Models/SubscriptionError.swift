//
//  SubscriptionError.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// Errors surfaced by ``SubscriptionManager`` through its `lastError` property.
///
/// The manager swallows two specific cases instead of surfacing them:
/// network failures (it flips `isOffline` to `true` and keeps the cached
/// state), and user-cancelled purchases (these are not failures from the
/// user's point of view).
public enum SubscriptionError: Error, Sendable {

    /// A method was called before ``SubscriptionManager/configure(_:)``.
    case notConfigured

    /// A purchase failed for a reason other than user cancellation.
    case purchaseFailed(underlying: Error)

    /// A restore call completed but no active entitlement was returned.
    case noActiveSubscriptionFound

    /// A restore call failed.
    case restoreFailed(underlying: Error)

    /// Loading offerings from RevenueCat failed.
    case offeringsLoadFailed(underlying: Error)

    /// Refreshing customer info failed for a non-network reason.
    case refreshFailed(underlying: Error)
}

extension SubscriptionError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "SubscriptionManager.configure(_:) was not called before use."
        case let .purchaseFailed(underlying):
            return "Purchase failed: \(underlying.localizedDescription)"
        case .noActiveSubscriptionFound:
            return "No active subscription was found to restore."
        case let .restoreFailed(underlying):
            return "Restore failed: \(underlying.localizedDescription)"
        case let .offeringsLoadFailed(underlying):
            return "Failed to load offerings: \(underlying.localizedDescription)"
        case let .refreshFailed(underlying):
            return "Failed to refresh subscription status: \(underlying.localizedDescription)"
        }
    }
}

extension SubscriptionError: Equatable {

    public static func == (lhs: SubscriptionError, rhs: SubscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured),
             (.noActiveSubscriptionFound, .noActiveSubscriptionFound):
            return true
        case let (.purchaseFailed(l), .purchaseFailed(r)),
             let (.restoreFailed(l), .restoreFailed(r)),
             let (.offeringsLoadFailed(l), .offeringsLoadFailed(r)),
             let (.refreshFailed(l), .refreshFailed(r)):
            return (l as NSError) == (r as NSError)
        default:
            return false
        }
    }
}
