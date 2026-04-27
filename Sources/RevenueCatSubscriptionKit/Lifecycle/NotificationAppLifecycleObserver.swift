//
//  NotificationAppLifecycleObserver.swift
//  RevenueCatSubscriptionKit
//
//  Created by Rouzbeh Abadi on 2026-04-27.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#elseif canImport(WatchKit)
import WatchKit
#endif

/// Default ``AppLifecycleObserving`` implementation that listens to a
/// platform-appropriate `Notification.Name`.
///
/// - iOS / iPadOS / tvOS / visionOS: `UIApplication.willEnterForegroundNotification`
/// - macOS: `NSApplication.willBecomeActiveNotification`
/// - watchOS: `WKApplication.willEnterForegroundNotification`
public final class NotificationAppLifecycleObserver: AppLifecycleObserving {

    private let notificationCenter: NotificationCenter
    private let notificationName: Notification.Name
    private var token: NSObjectProtocol?

    public init(notificationCenter: NotificationCenter = .default,
                notificationName: Notification.Name = .rcskAppWillEnterForeground) {
        self.notificationCenter = notificationCenter
        self.notificationName = notificationName
    }

    @MainActor
    public func startObserving(onForeground: @escaping @MainActor @Sendable () -> Void) {
        stopObserving()
        token = notificationCenter.addObserver(forName: notificationName,
                                               object: nil,
                                               queue: .main) { _ in
            MainActor.assumeIsolated {
                onForeground()
            }
        }
    }

    @MainActor
    public func stopObserving() {
        if let token {
            notificationCenter.removeObserver(token)
            self.token = nil
        }
    }

    deinit {
        if let token {
            notificationCenter.removeObserver(token)
        }
    }
}

extension Notification.Name {

    /// Platform-appropriate "app returned to foreground" notification name,
    /// used by ``NotificationAppLifecycleObserver`` when no override is
    /// supplied.
    public static var rcskAppWillEnterForeground: Notification.Name {
        #if os(watchOS)
        if #available(watchOS 7.0, *) {
            return WKApplication.willEnterForegroundNotification
        } else {
            return Notification.Name("WKApplicationWillEnterForegroundNotification")
        }
        #elseif canImport(UIKit)
        return UIApplication.willEnterForegroundNotification
        #elseif canImport(AppKit)
        return NSApplication.willBecomeActiveNotification
        #else
        return Notification.Name("RCSKAppWillEnterForegroundNotification")
        #endif
    }
}
