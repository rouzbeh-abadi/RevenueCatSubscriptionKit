//
//  UserDefaultsSubscriptionCache.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// `UserDefaults`-backed implementation of ``SubscriptionCache``.
///
/// Stores a single JSON blob under one key, so adding new fields to
/// ``CachedSubscriptionState`` doesn't require a migration step.
public final class UserDefaultsSubscriptionCache: SubscriptionCache {

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a cache backed by the given `UserDefaults` instance.
    ///
    /// - Parameters:
    ///   - defaults: The `UserDefaults` to read from and write to. Defaults
    ///     to `.standard`. Pass an app-group container's `UserDefaults` to
    ///     share state across an extension.
    ///   - keyPrefix: A namespace to prepend to the stored key, to avoid
    ///     collisions when multiple managers share a `UserDefaults`.
    public init(defaults: UserDefaults = .standard,
                keyPrefix: String = "rcsk") {
        self.defaults = defaults
        self.storageKey = "\(keyPrefix).cached_subscription_state"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.encoder = encoder
        self.decoder = decoder
    }

    public func loadState() -> CachedSubscriptionState? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        return try? decoder.decode(CachedSubscriptionState.self, from: data)
    }

    public func saveState(_ state: CachedSubscriptionState) {
        guard let data = try? encoder.encode(state) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    public func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
