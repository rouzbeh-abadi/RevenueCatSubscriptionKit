//
//  MockSubscriptionCache.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
@testable import RevenueCatSubscriptionKit

final class MockSubscriptionCache: SubscriptionCache {

    var storedState: CachedSubscriptionState?
    private(set) var loadCount = 0
    private(set) var saveCount = 0
    private(set) var clearCount = 0

    init(initial: CachedSubscriptionState? = nil) {
        self.storedState = initial
    }

    func loadState() -> CachedSubscriptionState? {
        loadCount += 1
        return storedState
    }

    func saveState(_ state: CachedSubscriptionState) {
        saveCount += 1
        storedState = state
    }

    func clear() {
        clearCount += 1
        storedState = nil
    }
}
