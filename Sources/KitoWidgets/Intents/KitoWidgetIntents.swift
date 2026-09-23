//
//  KitoWidgetIntents.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import AppIntents
import Foundation

/// Registers this package's intents with the system. Include it from an `AppIntentsPackage` in
/// both your app and your widget extension:
///
/// ```swift
/// struct AppIntentsBundle: AppIntentsPackage {
///     static var includedPackages: [any AppIntentsPackage.Type] { [KitoWidgetsIntents.self] }
/// }
/// ```
public struct KitoWidgetsIntents: AppIntentsPackage {}

/// Marks a task done or not done in a list stored in ``KitoWidgetStore/shared``. Used by
/// ``KitoListWidgetView``'s check toggles.
public struct KitoToggleTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Toggle Task"
    public static let description = IntentDescription("Marks a task in a Kito list widget as done or not done.")
    public static let isDiscoverable = false

    @Parameter(title: "Task ID")
    public var taskID: String

    @Parameter(title: "List", default: "kito.widgets.tasks")
    public var listKey: String

    public init() {}

    public init(taskID: String, listKey: String = KitoWidgetTask.defaultStoreKey) {
        self.taskID = taskID
        self.listKey = listKey
    }

    public func perform() async throws -> some IntentResult {
        try KitoWidgetStore.shared.update([KitoWidgetTask].self, forKey: listKey, default: []) { tasks in
            tasks.toggle(id: taskID)
        }
        KitoWidgetStore.reloadTimelines()
        return .result()
    }
}

/// Adds to a daily ``KitoWidgetCounter`` in ``KitoWidgetStore/shared`` — e.g. logs a glass of
/// water. Pass a negative amount to undo.
public struct KitoIncrementCounterIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log One More"
    public static let description = IntentDescription("Adds to a daily counter, like glasses of water.")

    @Parameter(title: "Counter", default: "kito.widgets.counter")
    public var counterKey: String

    @Parameter(title: "Amount", default: 1)
    public var amount: Int

    public init() {}

    public init(counterKey: String = KitoWidgetCounter.defaultStoreKey, amount: Int = 1) {
        self.counterKey = counterKey
        self.amount = amount
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let counter = try KitoWidgetStore.shared.update(KitoWidgetCounter.self, forKey: counterKey, default: KitoWidgetCounter()) {
            $0.increment(by: amount)
        }
        KitoWidgetStore.reloadTimelines()
        return .result(value: counter.count)
    }
}

/// Opens the app and leaves a URL for it to route to. Read it with
/// ``KitoWidgetStore/consumePendingDeepLink()`` when your scene becomes active. (For widgets you
/// can also use `Link` or `widgetURL`, which need no intent.)
public struct KitoOpenDeepLinkIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open in App"
    public static let description = IntentDescription("Opens the app at a specific screen.")
    public static let openAppWhenRun = true

    @Parameter(title: "Link")
    public var url: URL

    public init() {}

    public init(url: URL) {
        self.url = url
    }

    public func perform() async throws -> some IntentResult {
        try KitoWidgetStore.shared.save(url, forKey: KitoWidgetStore.pendingDeepLinkKey)
        return .result()
    }
}
