//
//  SubscriptionStatusResolver.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// Pure function that maps a snapshot of customer entitlements to a
/// ``SubscriptionStatus``.
///
/// Kept as a free-standing type so it can be exercised directly by unit tests
/// without involving the manager, the cache, or RevenueCat.
public enum SubscriptionStatusResolver {

    /// Resolves the status for the given target entitlement.
    ///
    /// - Parameters:
    ///   - snapshot: The customer-info snapshot to inspect.
    ///   - targetEntitlementID: The entitlement that gates premium access.
    ///   - now: The current moment, injected to keep the function pure.
    /// - Returns: ``SubscriptionStatus/premium`` if the entitlement is active;
    ///   ``SubscriptionStatus/expired`` if it was active in the past but its
    ///   expiration date is in the past; ``SubscriptionStatus/free`` otherwise.
    public static func resolve(snapshot: CustomerInfoSnapshot,
                               targetEntitlementID: String,
                               now: Date) -> SubscriptionStatus {
        if snapshot.isActive(targetEntitlementID) {
            return .premium
        }
        if let expiration = snapshot.expirationDate(for: targetEntitlementID),
           expiration < now {
            return .expired
        }
        return .free
    }
}
