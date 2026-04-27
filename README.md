# RevenueCatSubscriptionKit

[![CI](https://github.com/rouzbeh-abadi/RevenueCatSubscriptionKit/actions/workflows/ci.yml/badge.svg)](https://github.com/rouzbeh-abadi/RevenueCatSubscriptionKit/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/rouzbeh-abadi/RevenueCatSubscriptionKit)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A drop-in `@MainActor` subscription manager for [RevenueCat](https://www.revenuecat.com), built around `ObservableObject` so you can bind it directly to SwiftUI. Caches the last known state in `UserDefaults`, refreshes automatically on foreground, and falls back gracefully to that cache when the device is offline.

## Features

- **One-line setup.** Configure once with your RevenueCat API key and a premium entitlement identifier, then read `isPremiumUser` from anywhere.
- **SwiftUI-native.** `@MainActor` `ObservableObject` with `@Published` state — no glue code required.
- **Cached at launch.** Subscription state survives app restarts and offline launches via a pluggable `SubscriptionCache`.
- **Foreground refresh.** Re-fetches customer info every time the app returns from the background.
- **Offline-aware.** Connectivity errors set `isOffline = true` and preserve the cached state instead of surfacing an error.
- **Live updates.** Subscribes to RevenueCat's `PurchasesDelegate` callbacks and keeps published state in sync.
- **Cross-platform.** iOS, iPadOS, macOS, tvOS, watchOS, visionOS.
- **Fully unit-testable.** Every collaborator — purchases provider, cache, lifecycle observer, clock — sits behind a protocol, so the manager can be exercised end-to-end without touching the network.

## Requirements

- iOS 15+ / macOS 12+ / tvOS 15+ / watchOS 8+ / visionOS 1+
- Swift 6.0+ (Swift 6 language mode)
- Xcode 16+

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rouzbeh-abadi/RevenueCatSubscriptionKit.git",
             from: "1.0.0"),
]
```

…and to your target:

```swift
.target(name: "YourApp",
        dependencies: ["RevenueCatSubscriptionKit"])
```

Or, in Xcode, choose **File → Add Package Dependencies…** and enter the repository URL.

## Usage

### Configure once at launch

```swift
import SwiftUI
import RevenueCatSubscriptionKit

@main
struct MyApp: App {

    init() {
        SubscriptionManager.shared.configure(
            SubscriptionConfiguration(apiKey: "appl_…",
                                      premiumEntitlementID: "premium")
        )
    }

    var body: some Scene {
        WindowGroup { RootView() }
    }
}
```

### Bind to SwiftUI

```swift
struct RootView: View {
    @StateObject private var subscriptions = SubscriptionManager.shared

    var body: some View {
        if subscriptions.isPremiumUser {
            PremiumContentView()
        } else {
            PaywallView()
        }
    }
}
```

### Show a paywall

```swift
import RevenueCat
import RevenueCatSubscriptionKit

struct PaywallView: View {

    @StateObject private var subscriptions = SubscriptionManager.shared

    var body: some View {
        VStack(spacing: 16) {
            if let offering = subscriptions.currentOffering {
                ForEach(offering.availablePackages, id: \.identifier) { package in
                    Button(package.storeProduct.localizedTitle) {
                        Task { await subscriptions.purchase(package) }
                    }
                    .disabled(subscriptions.isPurchasing)
                }
            }

            Button("Restore Purchases") {
                Task { await subscriptions.restorePurchases() }
            }
            .disabled(subscriptions.isPurchasing)

            if let error = subscriptions.lastError {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
            }
        }
        .task { await subscriptions.loadOfferings() }
    }
}
```

### Inspect the resolved status

`SubscriptionStatus` carries the four states the manager will ever publish:

| Case        | When it applies                                              |
| ----------- | ------------------------------------------------------------ |
| `.unknown`  | Initial value before the first refresh and with no cached state. |
| `.free`     | The user has never had the premium entitlement, or has it expired with no recorded expiration. |
| `.premium`  | The configured entitlement is currently active.              |
| `.expired`  | The entitlement was active in the past but its expiration date is now in the past. |

```swift
switch subscriptions.subscriptionStatus {
case .unknown: ProgressView()
case .premium: PremiumBadge(expiresAt: subscriptions.expirationDate)
case .free:    UpsellView()
case .expired: RenewalView(expiredAt: subscriptions.expirationDate)
}
```

### Offline behaviour

When a refresh fails because of a connectivity issue (any of the recognised `URLError` codes, or `RevenueCat.ErrorCode.networkError`), the manager:

1. Keeps the last known `subscriptionStatus`, `isPremiumUser`, and `expirationDate` values.
2. Sets `isOffline = true` so your UI can display a banner.
3. Leaves `lastError` `nil` — connectivity hiccups are not treated as user-facing errors.

The next successful refresh clears `isOffline` automatically.

## Architecture

```
Sources/RevenueCatSubscriptionKit/
├── Core/
│   └── SubscriptionManager.swift        # The @MainActor ObservableObject
├── Models/                              # Pure value types
│   ├── SubscriptionStatus.swift
│   ├── CustomerInfoSnapshot.swift
│   ├── CachedSubscriptionState.swift
│   ├── SubscriptionError.swift
│   ├── SubscriptionLogLevel.swift
│   └── SubscriptionConfiguration.swift
├── Logic/                               # Pure functions, fully unit-tested
│   ├── SubscriptionStatusResolver.swift
│   ├── NetworkErrorClassifier.swift
│   └── PurchaseCancellationClassifier.swift
├── Caching/
│   ├── SubscriptionCache.swift          # Protocol
│   └── UserDefaultsSubscriptionCache.swift
├── Providers/
│   ├── PurchasesProviding.swift         # Protocol
│   └── RevenueCatPurchasesProvider.swift
└── Lifecycle/
    ├── AppLifecycleObserving.swift      # Protocol
    └── NotificationAppLifecycleObserver.swift
```

The manager itself is a thin co-ordinator: it asks the resolver for a status, persists the result through the cache, and listens to the provider's snapshot stream.

## Customisation

Every collaborator is a protocol with a default implementation, so you can swap any of them without subclassing:

```swift
let manager = SubscriptionManager(cache: KeychainSubscriptionCache(),
                                  lifecycleObserver: ScenePhaseObserver(),
                                  clock: { Date() },
                                  providerFactory: { config in
                                      MyCustomPurchasesProvider(configuration: config)
                                  })
```

This is also how the package's own tests run — `MockPurchasesProvider`, `MockSubscriptionCache`, and `MockAppLifecycleObserver` drive the manager through every code path without touching the network.

## Testing

```sh
swift test
```

The test suite covers:

- Status resolution against every entitlement permutation.
- Network-error classification across `URLError` codes and RevenueCat's typed errors.
- Purchase-cancellation detection in both `ErrorCode` and `NSError` shapes.
- `Codable` round-trips for the cached state.
- The `UserDefaults` cache (round-trip, key-prefix isolation, corrupted blob handling).
- Manager behaviour: cache hydration, configure idempotency, lifecycle-driven refresh, snapshot-stream updates, restore success/failure paths, offerings success/failure paths, offline fallback.

## License

Released under the [MIT License](LICENSE).
