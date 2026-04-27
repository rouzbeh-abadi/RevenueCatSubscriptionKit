//
//  SubscriptionStatus.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// The high-level subscription state surfaced by ``SubscriptionManager``.
///
/// The status is derived from the active entitlements and expiration dates
/// reported by RevenueCat, resolved against the configured premium entitlement.
public enum SubscriptionStatus: String, Codable, Equatable, Sendable, CaseIterable {

    /// The status has not yet been resolved. This is the initial value before
    /// the first refresh completes and no cached state is available.
    case unknown

    /// The user is on the free tier. The premium entitlement has never been
    /// active, or it was active in the past but no expiration record remains.
    case free

    /// The premium entitlement is currently active.
    case premium

    /// The premium entitlement was active in the past but has expired. The
    /// user can be re-engaged to renew.
    case expired
}
