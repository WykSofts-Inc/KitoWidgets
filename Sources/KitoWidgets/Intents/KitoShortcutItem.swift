//
//  KitoShortcutItem.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import AppIntents
import Foundation

/// A place in your app that Siri, Shortcuts and Spotlight can open — an example `AppEntity`
/// backed by ``KitoWidgetStore/shared``. Save your own list under ``storeKey``.
public struct KitoShortcutItem: AppEntity, Codable, Hashable, Sendable {
    /// Where ``KitoShortcutItemQuery`` reads the items from.
    public static let storeKey = "kito.widgets.shortcuts"

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Shortcut"
    public static let defaultQuery = KitoShortcutItemQuery()

    public var id: String
    public var title: String
    public var symbol: String
    public var url: URL

    public init(id: String, title: String, symbol: String, url: URL) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.url = url
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol))
    }

    /// Items served when nothing is saved under ``storeKey``.
    public static let samples: [KitoShortcutItem] = [
        ("inbox", "Inbox", "tray.fill"), ("new-task", "New Task", "plus.circle.fill"),
        ("today", "Today", "calendar"), ("settings", "Settings", "gearshape.fill"),
    ].compactMap { id, title, symbol in
        URL(string: "kito://\(id)").map { KitoShortcutItem(id: id, title: title, symbol: symbol, url: $0) }
    }

    /// The saved items, or ``samples``.
    public static func all(in store: KitoWidgetStore = .shared) -> [KitoShortcutItem] {
        store.load([KitoShortcutItem].self, forKey: storeKey) ?? samples
    }
}

/// Finds ``KitoShortcutItem``s by id, by name, or as suggestions.
public struct KitoShortcutItemQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [KitoShortcutItem.ID]) async throws -> [KitoShortcutItem] {
        let items = KitoShortcutItem.all()
        return identifiers.compactMap { id in items.first { $0.id == id } }
    }

    public func entities(matching string: String) async throws -> [KitoShortcutItem] {
        KitoShortcutItem.all().filter { $0.title.localizedCaseInsensitiveContains(string) }
    }

    public func suggestedEntities() async throws -> [KitoShortcutItem] {
        KitoShortcutItem.all()
    }
}

/// Opens a ``KitoShortcutItem``: the app launches and ``KitoWidgetStore/consumePendingDeepLink()``
/// returns the item's URL.
///
/// App Shortcuts must be declared in your app target, not a package:
///
/// ```swift
/// struct AppShortcuts: AppShortcutsProvider {
///     static var appShortcuts: [AppShortcut] {
///         AppShortcut(intent: KitoOpenShortcutIntent(), phrases: [
///             "Open \(\.$item) in \(.applicationName)",
///         ], shortTitle: "Open", systemImageName: "arrow.up.forward.app")
///         AppShortcut(intent: KitoIncrementCounterIntent(), phrases: [
///             "Log a glass of water in \(.applicationName)",
///         ], shortTitle: "Log water", systemImageName: "drop.fill")
///     }
/// }
/// ```
public struct KitoOpenShortcutIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Shortcut"
    public static let description = IntentDescription("Opens a screen of the app.")
    public static let openAppWhenRun = true

    @Parameter(title: "Shortcut")
    public var item: KitoShortcutItem

    public init() {}

    public init(item: KitoShortcutItem) {
        self.item = item
    }

    public func perform() async throws -> some IntentResult {
        try KitoWidgetStore.shared.save(item.url, forKey: KitoWidgetStore.pendingDeepLinkKey)
        return .result()
    }
}
