//
//  KitoWidgetStore.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import WidgetKit

/// Codable storage shared between your app and its widget extension through an App Group.
///
/// ```swift
/// let store = KitoWidgetStore(appGroup: "group.com.example.app")
/// try store.save(tasks, forKey: "tasks")
/// KitoWidgetStore.reloadTimelines(ofKind: "TasksWidget")
/// ```
///
/// The built-in intents use ``shared``, which reads the App Group identifier from the
/// `KitoWidgetsAppGroup` Info.plist key of whichever process is running (app or extension), so
/// add that key to both targets.
public struct KitoWidgetStore: @unchecked Sendable {
    /// The Info.plist key ``shared`` reads its App Group identifier from.
    public static let appGroupInfoKey = "KitoWidgetsAppGroup"

    /// Posted in-process after every write, so in-app previews can refresh. `object` is the key.
    public static let didChangeNotification = Notification.Name("KitoWidgetStoreDidChange")

    /// The store for the App Group named by the `KitoWidgetsAppGroup` Info.plist key, or the
    /// standard user defaults when the key is missing.
    public static var shared: KitoWidgetStore {
        KitoWidgetStore(appGroup: Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String)
    }

    /// The defaults values are written to.
    public let defaults: UserDefaults
    /// The App Group backing this store, or `nil` when it uses standard or injected defaults.
    public let appGroup: String?

    /// A store backed by an App Group's defaults. Falls back to `UserDefaults.standard` when
    /// `appGroup` is `nil` or the group isn't in this target's entitlements.
    public init(appGroup: String?) {
        if let appGroup, let suite = UserDefaults(suiteName: appGroup) {
            self.defaults = suite
            self.appGroup = appGroup
        } else {
            self.defaults = .standard
            self.appGroup = nil
        }
    }

    /// A store backed by any defaults, e.g. a throwaway suite in tests.
    public init(defaults: UserDefaults) {
        self.defaults = defaults
        self.appGroup = nil
    }

    /// Encodes `value` as JSON under `key`.
    public func save<Value: Encodable>(_ value: Value, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        defaults.set(data, forKey: key)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: key)
    }

    /// The value stored under `key`, or `nil` when it's missing or no longer decodes.
    public func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// The value stored under `key`, or `defaultValue`.
    public func load<Value: Decodable>(_ type: Value.Type, forKey key: String, default defaultValue: Value) -> Value {
        load(type, forKey: key) ?? defaultValue
    }

    /// Loads, mutates and saves in one step, returning the saved value.
    @discardableResult
    public func update<Value: Codable>(_ type: Value.Type, forKey key: String, default defaultValue: Value,
                                       _ mutate: (inout Value) -> Void) throws -> Value {
        var value = load(type, forKey: key, default: defaultValue)
        mutate(&value)
        try save(value, forKey: key)
        return value
    }

    /// Removes the value under `key`.
    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: key)
    }

    /// Asks WidgetKit to reload one kind of widget, or every widget when `kind` is `nil`.
    public static func reloadTimelines(ofKind kind: String? = nil) {
        if let kind {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Deep links

extension KitoWidgetStore {
    /// The key ``KitoOpenDeepLinkIntent`` leaves its URL under.
    public static let pendingDeepLinkKey = "kito.widgets.pendingDeepLink"

    /// Returns and clears the URL a widget intent asked the app to open. Call it when your scene
    /// becomes active.
    public func consumePendingDeepLink() -> URL? {
        guard let url = load(URL.self, forKey: Self.pendingDeepLinkKey) else { return nil }
        remove(forKey: Self.pendingDeepLinkKey)
        return url
    }
}
