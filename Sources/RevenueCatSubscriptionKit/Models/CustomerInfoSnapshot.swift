//
//  CustomerInfoSnapshot.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat

/// A value-type projection of the parts of `RevenueCat.CustomerInfo` that the
/// subscription manager actually reads.
///
/// Working with a snapshot rather than `CustomerInfo` directly keeps the core
/// logic pure and unit-testable. Production code converts a fresh
/// `CustomerInfo` via ``init(customerInfo:)``; tests construct snapshots
/// directly with the memberwise initialiser.
public struct CustomerInfoSnapshot: Equatable, Sendable {

    /// The set of entitlement identifiers that are currently active.
    public let activeEntitlementIDs: Set<String>

    /// Expiration dates for every entitlement the user has ever owned, keyed
    /// by entitlement identifier. Lifetime entitlements have no expiration and
    /// are absent from this dictionary.
    public let entitlementExpirations: [String: Date]

    /// The original (anonymous or aliased) RevenueCat user identifier, if
    /// available. Mostly useful for logging.
    public let originalAppUserID: String?

    public init(activeEntitlementIDs: Set<String>,
                entitlementExpirations: [String: Date] = [:],
                originalAppUserID: String? = nil) {
        self.activeEntitlementIDs = activeEntitlementIDs
        self.entitlementExpirations = entitlementExpirations
        self.originalAppUserID = originalAppUserID
    }

    /// An empty snapshot — no active entitlements, no expirations recorded.
    public static let empty = CustomerInfoSnapshot(activeEntitlementIDs: [])

    /// Whether the given entitlement is currently active.
    public func isActive(_ entitlementID: String) -> Bool {
        activeEntitlementIDs.contains(entitlementID)
    }

    /// The expiration date for the given entitlement, or `nil` if the user
    /// has never held it (or it is a lifetime entitlement).
    public func expirationDate(for entitlementID: String) -> Date? {
        entitlementExpirations[entitlementID]
    }
}

extension CustomerInfoSnapshot {

    /// Builds a snapshot from a fresh `CustomerInfo` returned by RevenueCat.
    public init(customerInfo: CustomerInfo) {
        let activeIDs = Set(customerInfo.entitlements.active.keys)
        var expirations: [String: Date] = [:]
        for (key, entitlement) in customerInfo.entitlements.all {
            if let exp = entitlement.expirationDate {
                expirations[key] = exp
            }
        }
        self.init(activeEntitlementIDs: activeIDs,
                  entitlementExpirations: expirations,
                  originalAppUserID: customerInfo.originalAppUserId)
    }
}
