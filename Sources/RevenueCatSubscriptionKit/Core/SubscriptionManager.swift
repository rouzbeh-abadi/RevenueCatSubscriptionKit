//
//  SubscriptionManager.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Combine
import Foundation
import RevenueCat

/// The single source of truth for the user's subscription state.
///
/// Configure once at app launch:
///
/// ```swift
/// SubscriptionManager.shared.configure(
///     SubscriptionConfiguration(apiKey: "appl_…",
///                               premiumEntitlementID: "premium")
/// )
/// ```
///
/// Then bind to its published properties from SwiftUI views:
///
/// ```swift
/// @StateObject private var subscriptions = SubscriptionManager.shared
///
/// var body: some View {
///     if subscriptions.isPremiumUser {
///         PremiumContentView()
///     } else {
///         PaywallView()
///     }
/// }
/// ```
///
/// State is persisted between launches via the configured ``SubscriptionCache``,
/// and refreshed automatically every time the app returns from the background.
/// On a network failure the manager falls back silently to the cached state and
/// flips ``isOffline`` to `true` instead of surfacing an error.
@MainActor
public final class SubscriptionManager: ObservableObject {

    // MARK: - Singleton

    /// A shared, lazily-initialised instance for app-wide use. Apps that use
    /// dependency injection or run the manager in tests can construct their
    /// own instance with ``init(cache:lifecycleObserver:clock:providerFactory:)``.
    public static let shared = SubscriptionManager()

    // MARK: - Published state

    /// The high-level subscription state.
    @Published public private(set) var subscriptionStatus: SubscriptionStatus

    /// `true` when the configured premium entitlement is currently active.
    /// Equivalent to `subscriptionStatus == .premium`.
    @Published public private(set) var isPremiumUser: Bool

    /// Expiration of the configured premium entitlement, if known. `nil` for
    /// lifetime entitlements or when the user has never owned the entitlement.
    @Published public private(set) var expirationDate: Date?

    /// The current RevenueCat offering, populated by ``loadOfferings()`` and
    /// used by paywall UI.
    @Published public private(set) var currentOffering: Offering?

    /// `true` while a `purchase` or `restorePurchases` call is in flight.
    @Published public private(set) var isPurchasing: Bool = false

    /// `true` when the most recent refresh failed for connectivity reasons.
    /// The published state continues to reflect the last successful fetch
    /// (or the cached value loaded at launch).
    @Published public private(set) var isOffline: Bool = false

    /// The most recent surfaced error, or `nil` if no error is pending.
    /// Cleared at the start of every purchase/restore.
    @Published public private(set) var lastError: SubscriptionError?

    /// The configuration that was passed to ``configure(_:)``, or `nil` if
    /// the manager has not been configured yet.
    public private(set) var configuration: SubscriptionConfiguration?

    // MARK: - Dependencies

    private let cache: SubscriptionCache
    private let lifecycleObserver: AppLifecycleObserving?
    private let clock: @Sendable () -> Date
    private let providerFactory: @MainActor (SubscriptionConfiguration) -> PurchasesProviding

    private var purchasesProvider: PurchasesProviding?
    nonisolated(unsafe) private var snapshotsTask: Task<Void, Never>?

    // MARK: - Init

    /// Creates a manager with the given dependencies.
    ///
    /// All parameters have production-ready defaults; tests typically inject
    /// mocks for `cache`, `providerFactory`, and `lifecycleObserver`, and a
    /// fixed `clock` so status resolution is deterministic.
    public init(cache: SubscriptionCache = UserDefaultsSubscriptionCache(),
                lifecycleObserver: AppLifecycleObserving? = NotificationAppLifecycleObserver(),
                clock: @escaping @Sendable () -> Date = Date.init,
                providerFactory: @escaping @MainActor (SubscriptionConfiguration) -> PurchasesProviding
                    = SubscriptionManager.defaultProviderFactory) {
        self.cache = cache
        self.lifecycleObserver = lifecycleObserver
        self.clock = clock
        self.providerFactory = providerFactory

        let cached = cache.loadState()
        self.subscriptionStatus = cached?.status ?? .unknown
        self.isPremiumUser = cached?.isPremium ?? false
        self.expirationDate = cached?.expirationDate
    }

    deinit {
        snapshotsTask?.cancel()
    }

    /// Default factory used by the shared instance. Builds a
    /// ``RevenueCatPurchasesProvider`` from the configuration.
    public static let defaultProviderFactory:
        @MainActor (SubscriptionConfiguration) -> PurchasesProviding = { configuration in
            RevenueCatPurchasesProvider(configuration: configuration)
        }

    // MARK: - Configuration

    /// Wires up RevenueCat, starts observing customer-info updates, registers
    /// for foreground notifications, and kicks off the first refresh.
    ///
    /// Calling this more than once is a no-op; the first invocation wins so
    /// `Purchases.configure(...)` is never called twice.
    public func configure(_ configuration: SubscriptionConfiguration) {
        guard self.configuration == nil else { return }
        self.configuration = configuration

        let provider = providerFactory(configuration)
        self.purchasesProvider = provider

        startObservingUpdates(from: provider)
        lifecycleObserver?.startObserving { [weak self] in
            Task { @MainActor in
                await self?.refresh()
            }
        }

        Task { @MainActor in
            await self.refresh()
        }
    }

    // MARK: - Public API

    /// Re-fetches customer info from RevenueCat. Called automatically on
    /// configure and every time the app returns to the foreground; expose to
    /// the user behind a "refresh" affordance if desired.
    public func refresh() async {
        guard let provider = purchasesProvider else {
            lastError = .notConfigured
            return
        }
        do {
            let snapshot = try await provider.fetchSnapshot()
            apply(snapshot: snapshot)
        } catch {
            handleRefreshError(error)
        }
    }

    /// Loads the current RevenueCat offering for use in paywall UI. Stores
    /// the result in ``currentOffering``.
    public func loadOfferings() async {
        guard let provider = purchasesProvider else {
            lastError = .notConfigured
            return
        }
        do {
            currentOffering = try await provider.fetchCurrentOffering()
        } catch {
            lastError = .offeringsLoadFailed(underlying: error)
        }
    }

    /// Initiates a purchase. User cancellation is silently swallowed; any
    /// other failure is surfaced through ``lastError``.
    public func purchase(_ package: Package) async {
        guard let provider = purchasesProvider else {
            lastError = .notConfigured
            return
        }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }
        do {
            let snapshot = try await provider.purchase(package)
            apply(snapshot: snapshot)
        } catch {
            handlePurchaseError(error)
        }
    }

    /// Restores any previously purchased entitlements. Sets
    /// ``lastError`` to ``SubscriptionError/noActiveSubscriptionFound`` if
    /// the call succeeds but no entitlement was restored.
    public func restorePurchases() async {
        guard let provider = purchasesProvider else {
            lastError = .notConfigured
            return
        }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }
        do {
            let snapshot = try await provider.restorePurchases()
            apply(snapshot: snapshot)
            if !isPremiumUser {
                lastError = .noActiveSubscriptionFound
            }
        } catch {
            lastError = .restoreFailed(underlying: error)
        }
    }

    /// Clears the surfaced ``lastError``, e.g. after the host UI has
    /// presented it to the user.
    public func clearLastError() {
        lastError = nil
    }

    // MARK: - State application

    func apply(snapshot: CustomerInfoSnapshot) {
        guard let configuration else { return }
        let now = clock()
        let entitlementID = configuration.premiumEntitlementID
        let status = SubscriptionStatusResolver.resolve(snapshot: snapshot,
                                                        targetEntitlementID: entitlementID,
                                                        now: now)
        let expDate = snapshot.expirationDate(for: entitlementID)

        subscriptionStatus = status
        expirationDate = expDate
        isPremiumUser = (status == .premium)
        isOffline = false

        cache.saveState(CachedSubscriptionState(status: status,
                                                isPremium: isPremiumUser,
                                                expirationDate: expDate,
                                                updatedAt: now))
    }

    private func handleRefreshError(_ error: Error) {
        if NetworkErrorClassifier.isNetworkError(error) {
            isOffline = true
        } else {
            lastError = .refreshFailed(underlying: error)
        }
    }

    private func handlePurchaseError(_ error: Error) {
        if PurchaseCancellationClassifier.isUserCancellation(error) {
            return
        }
        lastError = .purchaseFailed(underlying: error)
    }

    private func startObservingUpdates(from provider: PurchasesProviding) {
        snapshotsTask?.cancel()
        snapshotsTask = Task { @MainActor [weak self] in
            for await snapshot in provider.snapshotUpdates {
                self?.apply(snapshot: snapshot)
            }
        }
    }
}
