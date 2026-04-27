//
//  CustomerInfoSnapshotTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("CustomerInfoSnapshot")
struct CustomerInfoSnapshotTests {

    @Test("Empty snapshot has no active entitlements and no expirations")
    func empty() {
        let snapshot = CustomerInfoSnapshot.empty
        #expect(snapshot.activeEntitlementIDs.isEmpty)
        #expect(snapshot.entitlementExpirations.isEmpty)
        #expect(snapshot.originalAppUserID == nil)
    }

    @Test("isActive returns true only for known active entitlements")
    func isActive() {
        let snapshot = CustomerInfoSnapshot(activeEntitlementIDs: ["premium", "pro"])
        #expect(snapshot.isActive("premium"))
        #expect(snapshot.isActive("pro"))
        #expect(!snapshot.isActive("plus"))
    }

    @Test("expirationDate returns nil for entitlements without a recorded date")
    func expirationDateMissing() {
        let snapshot = CustomerInfoSnapshot(activeEntitlementIDs: ["premium"])
        #expect(snapshot.expirationDate(for: "premium") == nil)
    }

    @Test("expirationDate returns the recorded value when present")
    func expirationDatePresent() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = CustomerInfoSnapshot(activeEntitlementIDs: [],
                                            entitlementExpirations: ["premium": date])
        #expect(snapshot.expirationDate(for: "premium") == date)
    }

    @Test("Snapshot equality is structural")
    func equality() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let a = CustomerInfoSnapshot(activeEntitlementIDs: ["premium"],
                                     entitlementExpirations: ["premium": date],
                                     originalAppUserID: "user-1")
        let b = CustomerInfoSnapshot(activeEntitlementIDs: ["premium"],
                                     entitlementExpirations: ["premium": date],
                                     originalAppUserID: "user-1")
        let c = CustomerInfoSnapshot(activeEntitlementIDs: [],
                                     entitlementExpirations: ["premium": date],
                                     originalAppUserID: "user-1")
        #expect(a == b)
        #expect(a != c)
    }
}
