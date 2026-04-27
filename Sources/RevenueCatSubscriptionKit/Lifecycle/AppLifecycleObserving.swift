//
//  AppLifecycleObserving.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

/// Notifies the manager when the app returns from the background, so it can
/// re-fetch customer info.
///
/// Decoupled into a protocol so the manager can be unit-tested without ever
/// touching `UIApplication`/`NSApplication`/`WKApplication`, and so that
/// host apps with custom lifecycle plumbing can supply their own observer.
public protocol AppLifecycleObserving: AnyObject {

    /// Begins observing. Calls `onForeground` on the main actor every time
    /// the app returns to the foreground.
    @MainActor
    func startObserving(onForeground: @escaping @MainActor @Sendable () -> Void)

    /// Stops observing. Safe to call multiple times.
    @MainActor
    func stopObserving()
}
