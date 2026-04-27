//
//  MockAppLifecycleObserver.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation
@testable import RevenueCatSubscriptionKit

@MainActor
final class MockAppLifecycleObserver: AppLifecycleObserving {

    private var onForegroundHandler: (@MainActor @Sendable () -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    var isObserving: Bool { onForegroundHandler != nil }

    func startObserving(onForeground: @escaping @MainActor @Sendable () -> Void) {
        startCount += 1
        onForegroundHandler = onForeground
    }

    func stopObserving() {
        stopCount += 1
        onForegroundHandler = nil
    }

    /// Synchronously fires the registered handler, simulating an
    /// app-foregrounded event.
    func fireForeground() {
        onForegroundHandler?()
    }
}
