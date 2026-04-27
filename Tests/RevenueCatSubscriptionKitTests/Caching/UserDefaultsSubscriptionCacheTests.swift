//
//  UserDefaultsSubscriptionCacheTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("UserDefaultsSubscriptionCache")
struct UserDefaultsSubscriptionCacheTests {

    private static func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "rcsk-test-\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test("Returns nil when nothing has been written")
    func emptyLoad() {
        let defaults = Self.makeIsolatedDefaults()
        let cache = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "test")
        #expect(cache.loadState() == nil)
    }

    @Test("Round-trips a saved state")
    func saveLoad() {
        let defaults = Self.makeIsolatedDefaults()
        let cache = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "test")
        let state = CachedSubscriptionState(status: .premium,
                                            isPremium: true,
                                            expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
                                            updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        cache.saveState(state)
        #expect(cache.loadState() == state)
    }

    @Test("clear() removes the persisted state")
    func clear() {
        let defaults = Self.makeIsolatedDefaults()
        let cache = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "test")
        let state = CachedSubscriptionState(status: .free,
                                            isPremium: false,
                                            expirationDate: nil,
                                            updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        cache.saveState(state)
        cache.clear()
        #expect(cache.loadState() == nil)
    }

    @Test("Returns nil when the stored blob can no longer be decoded")
    func corruptedBlob() {
        let defaults = Self.makeIsolatedDefaults()
        let cache = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "test")
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: "test.cached_subscription_state")
        #expect(cache.loadState() == nil)
    }

    @Test("Different key prefixes do not collide")
    func keyPrefixIsolation() {
        let defaults = Self.makeIsolatedDefaults()
        let a = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "a")
        let b = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "b")
        let stateA = CachedSubscriptionState(status: .premium,
                                             isPremium: true,
                                             expirationDate: nil,
                                             updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        a.saveState(stateA)
        #expect(b.loadState() == nil)
        #expect(a.loadState() == stateA)
    }

    @Test("Saving overwrites the previous value")
    func saveOverwrites() {
        let defaults = Self.makeIsolatedDefaults()
        let cache = UserDefaultsSubscriptionCache(defaults: defaults, keyPrefix: "test")
        let first = CachedSubscriptionState(status: .free,
                                            isPremium: false,
                                            expirationDate: nil,
                                            updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let second = CachedSubscriptionState(status: .premium,
                                             isPremium: true,
                                             expirationDate: Date(timeIntervalSince1970: 1_900_000_000),
                                             updatedAt: Date(timeIntervalSince1970: 1_750_000_000))
        cache.saveState(first)
        cache.saveState(second)
        #expect(cache.loadState() == second)
    }
}
