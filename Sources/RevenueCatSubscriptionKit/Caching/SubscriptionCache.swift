//
//  SubscriptionCache.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// Persists the most recently observed ``CachedSubscriptionState`` so the UI
/// can render a sensible value at launch before the first network round-trip
/// completes (or when the device is offline).
///
/// The default implementation is ``UserDefaultsSubscriptionCache``. Provide a
/// custom conformance to back the cache with the keychain, an app-group
/// container, or any other store.
public protocol SubscriptionCache: AnyObject {

    /// Returns the most recently persisted state, or `nil` if nothing has
    /// been written yet (or the persisted blob can no longer be decoded).
    func loadState() -> CachedSubscriptionState?

    /// Persists the given state, replacing any previously stored value.
    func saveState(_ state: CachedSubscriptionState)

    /// Removes any persisted state.
    func clear()
}
