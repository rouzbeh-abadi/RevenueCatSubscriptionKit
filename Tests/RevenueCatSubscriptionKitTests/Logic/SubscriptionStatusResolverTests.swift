//
//  SubscriptionStatusResolverTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("SubscriptionStatusResolver")
struct SubscriptionStatusResolverTests {

    private static let now = TestDates.fixedNow

    @Test("Active target entitlement resolves to .premium")
    func activeIsPremium() {
        let snapshot = CustomerInfoSnapshot(
            activeEntitlementIDs: ["premium"],
            entitlementExpirations: ["premium": Self.now.addingTimeInterval(86_400)]
        )
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .premium)
    }

    @Test("Past expiration with no active entitlement resolves to .expired")
    func pastExpirationIsExpired() {
        let snapshot = CustomerInfoSnapshot(
            activeEntitlementIDs: [],
            entitlementExpirations: ["premium": Self.now.addingTimeInterval(-1)]
        )
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .expired)
    }

    @Test("No record of the entitlement resolves to .free")
    func unknownIsFree() {
        let snapshot = CustomerInfoSnapshot.neverSubscribed
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .free)
    }

    @Test("Active entitlement with expiration in the past still wins (RevenueCat grace period)")
    func activeBeatsExpiredFlag() {
        let snapshot = CustomerInfoSnapshot(
            activeEntitlementIDs: ["premium"],
            entitlementExpirations: ["premium": Self.now.addingTimeInterval(-86_400)]
        )
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .premium)
    }

    @Test("Different active entitlement does not satisfy target")
    func differentEntitlementIsFree() {
        let status = SubscriptionStatusResolver.resolve(snapshot: .activeOtherEntitlement,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .free)
    }

    @Test("Target customised via configuration")
    func customTargetEntitlement() {
        let status = SubscriptionStatusResolver.resolve(snapshot: .activeOtherEntitlement,
                                                        targetEntitlementID: "pro",
                                                        now: Self.now)
        #expect(status == .premium)
    }

    @Test("Expiration exactly equal to now is not yet expired")
    func expirationAtNowIsFree() {
        let snapshot = CustomerInfoSnapshot(
            activeEntitlementIDs: [],
            entitlementExpirations: ["premium": Self.now]
        )
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: "premium",
                                                        now: Self.now)
        #expect(status == .free)
    }
}
