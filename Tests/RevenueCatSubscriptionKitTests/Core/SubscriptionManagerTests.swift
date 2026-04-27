//
//  SubscriptionManagerTests.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
import RevenueCat
import Testing
@testable import RevenueCatSubscriptionKit

@Suite("SubscriptionManager")
@MainActor
struct SubscriptionManagerTests {

    // MARK: - Builders

    private func makeManager(provider: MockPurchasesProvider = MockPurchasesProvider(),
                             cache: MockSubscriptionCache = MockSubscriptionCache(),
                             observer: MockAppLifecycleObserver = MockAppLifecycleObserver())
        -> SubscriptionManager {
        SubscriptionManager(cache: cache,
                            lifecycleObserver: observer,
                            clock: TestDates.fixedNowClock,
                            providerFactory: { _ in provider })
    }

    // MARK: - Initial state

    @Test("Initial state is .unknown when the cache is empty")
    func initialUnknownState() {
        let manager = makeManager()
        #expect(manager.subscriptionStatus == .unknown)
        #expect(!manager.isPremiumUser)
        #expect(manager.expirationDate == nil)
        #expect(manager.configuration == nil)
    }

    @Test("Hydrates published state from the cache at init")
    func hydratesFromCache() {
        let exp = TestDates.fixedNow.addingTimeInterval(86_400)
        let cache = MockSubscriptionCache(initial: CachedSubscriptionState(
            status: .premium,
            isPremium: true,
            expirationDate: exp,
            updatedAt: TestDates.fixedNow
        ))
        let manager = makeManager(cache: cache)
        #expect(manager.subscriptionStatus == .premium)
        #expect(manager.isPremiumUser)
        #expect(manager.expirationDate == exp)
        #expect(cache.loadCount == 1)
    }

    // MARK: - Configure

    @Test("configure() applies the first fetched snapshot and persists it")
    func configureAppliesSnapshot() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.activePremium))
        let cache = MockSubscriptionCache()
        let manager = makeManager(provider: provider, cache: cache)

        manager.configure(.test)

        await waitFor { manager.subscriptionStatus == .premium }
        #expect(manager.isPremiumUser)
        #expect(manager.subscriptionStatus == .premium)
        #expect(manager.expirationDate != nil)
        #expect(cache.saveCount >= 1)
        #expect(cache.storedState?.status == .premium)
        #expect(manager.configuration == .test)
    }

    @Test("configure() called twice is a no-op on the second call")
    func configureIsIdempotent() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.activePremium))
        let manager = makeManager(provider: provider)

        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        let differentConfig = SubscriptionConfiguration(apiKey: "other-key",
                                                       premiumEntitlementID: "vip")
        manager.configure(differentConfig)

        #expect(manager.configuration == .test)
    }

    @Test("configure() registers the lifecycle observer")
    func configureStartsObserver() async {
        let observer = MockAppLifecycleObserver()
        let manager = makeManager(observer: observer)
        manager.configure(.test)
        await waitFor { observer.isObserving }
        #expect(observer.startCount == 1)
    }

    // MARK: - Refresh

    @Test("refresh() before configure surfaces .notConfigured")
    func refreshBeforeConfigureFails() async {
        let manager = makeManager()
        await manager.refresh()
        #expect(manager.lastError == .notConfigured)
    }

    @Test("refresh() updates state on success and clears the offline flag")
    func refreshSuccessClearsOffline() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        provider.setFetchResult(.success(.activePremium))
        await manager.refresh()

        #expect(manager.subscriptionStatus == .premium)
        #expect(!manager.isOffline)
    }

    @Test("Network error sets isOffline and preserves cached state")
    func networkErrorGoesOffline() async {
        let exp = TestDates.fixedNow.addingTimeInterval(86_400)
        let cache = MockSubscriptionCache(initial: CachedSubscriptionState(
            status: .premium,
            isPremium: true,
            expirationDate: exp,
            updatedAt: TestDates.fixedNow
        ))
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.failure(URLError(.notConnectedToInternet)))
        let manager = makeManager(provider: provider, cache: cache)

        manager.configure(.test)
        await waitFor { manager.isOffline }

        #expect(manager.isOffline)
        #expect(manager.subscriptionStatus == .premium)
        #expect(manager.isPremiumUser)
        #expect(manager.lastError == nil)
    }

    @Test("Non-network error surfaces .refreshFailed")
    func nonNetworkErrorSurfaced() async {
        let provider = MockPurchasesProvider()
        let serverError = NSError(domain: "RevenueCat", code: 7_001)
        provider.setFetchResult(.failure(serverError))
        let manager = makeManager(provider: provider)

        manager.configure(.test)
        await waitFor { manager.lastError != nil }

        if case .refreshFailed = manager.lastError {
            // expected
        } else {
            Issue.record("Expected .refreshFailed, got \(String(describing: manager.lastError))")
        }
        #expect(!manager.isOffline)
    }

    // MARK: - Lifecycle

    @Test("Foreground notifications trigger an additional refresh")
    func foregroundFiresRefresh() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        let observer = MockAppLifecycleObserver()
        let manager = makeManager(provider: provider, observer: observer)

        manager.configure(.test)
        await waitFor { provider.fetchCallCount >= 1 }
        let baseline = provider.fetchCallCount

        observer.fireForeground()
        await waitFor { provider.fetchCallCount > baseline }

        #expect(provider.fetchCallCount > baseline)
    }

    // MARK: - Snapshot stream

    @Test("Snapshot stream updates apply through to published state")
    func streamUpdatesApply() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.subscriptionStatus == .free }

        provider.emit(.activePremium)
        await waitFor { manager.subscriptionStatus == .premium }

        #expect(manager.subscriptionStatus == .premium)
        #expect(manager.isPremiumUser)
    }

    // MARK: - Restore

    @Test("restorePurchases() applies an active snapshot")
    func restoreSuccess() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        provider.setRestoreResult(.success(.activePremium))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        await manager.restorePurchases()

        #expect(manager.subscriptionStatus == .premium)
        #expect(manager.isPremiumUser)
        #expect(!manager.isPurchasing)
        #expect(manager.lastError == nil)
        #expect(provider.restoreCallCount == 1)
    }

    @Test("restorePurchases() with no entitlements surfaces .noActiveSubscriptionFound")
    func restoreNoEntitlement() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        provider.setRestoreResult(.success(.neverSubscribed))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        await manager.restorePurchases()

        #expect(manager.lastError == .noActiveSubscriptionFound)
    }

    @Test("restorePurchases() failure surfaces .restoreFailed")
    func restoreFailure() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        provider.setRestoreResult(.failure(NSError(domain: "RevenueCat", code: 7_001)))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        await manager.restorePurchases()

        if case .restoreFailed = manager.lastError {
            // expected
        } else {
            Issue.record("Expected .restoreFailed, got \(String(describing: manager.lastError))")
        }
    }

    @Test("restorePurchases() before configure surfaces .notConfigured")
    func restoreBeforeConfigure() async {
        let manager = makeManager()
        await manager.restorePurchases()
        #expect(manager.lastError == .notConfigured)
    }

    // MARK: - Offerings

    @Test("loadOfferings() before configure surfaces .notConfigured")
    func offeringsBeforeConfigure() async {
        let manager = makeManager()
        await manager.loadOfferings()
        #expect(manager.lastError == .notConfigured)
    }

    @Test("loadOfferings() failure surfaces .offeringsLoadFailed")
    func offeringsFailure() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        provider.setOfferingResult(.failure(NSError(domain: "RevenueCat", code: 7_002)))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        await manager.loadOfferings()

        if case .offeringsLoadFailed = manager.lastError {
            // expected
        } else {
            Issue.record("Expected .offeringsLoadFailed, got \(String(describing: manager.lastError))")
        }
    }

    @Test("loadOfferings() success without a current offering stores nil")
    func offeringsNilSuccess() async {
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        provider.setOfferingResult(.success(nil))
        let manager = makeManager(provider: provider)
        manager.configure(.test)
        await waitFor { manager.configuration != nil }

        await manager.loadOfferings()

        #expect(manager.currentOffering == nil)
        #expect(manager.lastError == nil)
    }

    // MARK: - Error housekeeping

    @Test("clearLastError() resets lastError")
    func clearLastErrorResets() async {
        let manager = makeManager()
        await manager.refresh()
        #expect(manager.lastError == .notConfigured)
        manager.clearLastError()
        #expect(manager.lastError == nil)
    }

    // MARK: - Apply: status transitions and caching

    @Test("apply() transitions free → premium and writes to the cache")
    func applyTransitionsAndCaches() async {
        let cache = MockSubscriptionCache()
        let provider = MockPurchasesProvider()
        provider.setFetchResult(.success(.neverSubscribed))
        let manager = makeManager(provider: provider, cache: cache)
        manager.configure(.test)
        await waitFor { cache.storedState?.status == .free }

        manager.apply(snapshot: .activePremium)

        #expect(manager.subscriptionStatus == .premium)
        #expect(cache.storedState?.status == .premium)
        #expect(cache.storedState?.isPremium == true)
    }

    @Test("apply() before configure is a no-op")
    func applyBeforeConfigureIsNoop() {
        let cache = MockSubscriptionCache()
        let manager = makeManager(cache: cache)
        manager.apply(snapshot: .activePremium)
        #expect(manager.subscriptionStatus == .unknown)
        #expect(cache.saveCount == 0)
    }
}
