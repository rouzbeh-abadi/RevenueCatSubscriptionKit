//
//  TestFixtures.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
@testable import RevenueCatSubscriptionKit

enum TestDates {
    static let fixedNow = Date(timeIntervalSince1970: 1_750_000_000)
    static var fixedNowClock: @Sendable () -> Date { { fixedNow } }
}

extension SubscriptionConfiguration {
    static let test = SubscriptionConfiguration(apiKey: "test-key",
                                                premiumEntitlementID: "premium",
                                                cacheKeyPrefix: "rcsk-test",
                                                logLevel: .error)
}

extension CustomerInfoSnapshot {

    static let activePremium = CustomerInfoSnapshot(
        activeEntitlementIDs: ["premium"],
        entitlementExpirations: [
            "premium": TestDates.fixedNow.addingTimeInterval(86_400 * 30),
        ]
    )

    static let expiredPremium = CustomerInfoSnapshot(
        activeEntitlementIDs: [],
        entitlementExpirations: [
            "premium": TestDates.fixedNow.addingTimeInterval(-86_400),
        ]
    )

    static let neverSubscribed = CustomerInfoSnapshot(
        activeEntitlementIDs: [],
        entitlementExpirations: [:]
    )

    static let activeOtherEntitlement = CustomerInfoSnapshot(
        activeEntitlementIDs: ["pro"],
        entitlementExpirations: [
            "pro": TestDates.fixedNow.addingTimeInterval(86_400 * 30),
        ]
    )
}

/// Polls `condition` on the main actor with a tiny interval until it
/// returns `true` or the deadline expires. Useful for awaiting state
/// changes triggered by detached tasks.
@MainActor
func waitFor(timeout: TimeInterval = 1.0,
             _ condition: @MainActor () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}
