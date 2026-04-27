//
//  SubscriptionConfiguration.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// Settings passed to ``SubscriptionManager/configure(_:)`` to bind the
/// manager to a specific RevenueCat project and entitlement.
///
/// ```swift
/// SubscriptionManager.shared.configure(
///     SubscriptionConfiguration(apiKey: "appl_…",
///                               premiumEntitlementID: "premium")
/// )
/// ```
public struct SubscriptionConfiguration: Sendable, Equatable {

    /// The RevenueCat API key for the current platform (e.g. an `appl_…` key
    /// for Apple platforms).
    public let apiKey: String

    /// The identifier of the entitlement that gates premium features in the
    /// RevenueCat dashboard.
    public let premiumEntitlementID: String

    /// A namespace prepended to every key written to `UserDefaults` by the
    /// default cache. Override to avoid collisions when multiple subscription
    /// managers share a `UserDefaults` instance, or to scope the cache to an
    /// app group.
    public let cacheKeyPrefix: String

    /// The verbosity of the underlying RevenueCat SDK logs.
    public let logLevel: SubscriptionLogLevel

    /// An optional appUserID to forward to `Purchases.configure`. When `nil`,
    /// RevenueCat generates an anonymous ID and persists it across launches.
    public let appUserID: String?

    public init(apiKey: String,
                premiumEntitlementID: String = "premium",
                cacheKeyPrefix: String = "rcsk",
                logLevel: SubscriptionLogLevel = .warn,
                appUserID: String? = nil) {
        self.apiKey = apiKey
        self.premiumEntitlementID = premiumEntitlementID
        self.cacheKeyPrefix = cacheKeyPrefix
        self.logLevel = logLevel
        self.appUserID = appUserID
    }
}

