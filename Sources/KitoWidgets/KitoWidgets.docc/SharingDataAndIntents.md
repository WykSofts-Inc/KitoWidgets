# Sharing Data and Intents

Share data between your app and its widget extension, and make widgets interactive with App Intents.

## Overview

A widget extension runs in its own process, so the app and the extension share
data through an App Group. ``KitoWidgetStore`` reads and writes `Codable` values
in the App Group's `UserDefaults`, and the bundled intents use the same store to
update list and counter widgets without opening the app.

### Configure the App Group

Add the App Groups entitlement to both the app and the widget extension, then set
the `KitoWidgetsAppGroup` key in both targets' `Info.plist` to the group's
identifier. ``KitoWidgetStore/shared`` — the store the intents use — reads its
App Group from that key. Without it, the store falls back to standard defaults,
which works for in-app previews but is not shared with the widget.

### Save and load values

```swift
let store = KitoWidgetStore(appGroup: "group.com.example.app")
try store.save(balance, forKey: "balance")
let saved = store.load(Balance.self, forKey: "balance")

try store.update(KitoWidgetCounter.self, forKey: "water", default: KitoWidgetCounter()) {
    $0.increment()
}
KitoWidgetStore.reloadTimelines(ofKind: "Balance")   // or nil for every widget
```

### Make widgets interactive

``KitoListWidgetView`` draws each check as a toggle running
``KitoToggleTaskIntent``, and ``KitoCounterWidgetView`` has a "+" button running
``KitoIncrementCounterIntent``. Save the task list where the intent looks for it:

```swift
try KitoWidgetStore.shared.save(tasks, forKey: KitoWidgetTask.defaultStoreKey)
KitoWidgetStore.reloadTimelines(ofKind: "Tasks")
```

Your own buttons can run the same intents:

```swift
Button(intent: KitoIncrementCounterIntent(counterKey: "water")) {
    Label("Log a glass", systemImage: "drop.fill")
}
```

### Register the intents

Include ``KitoWidgetsIntents`` in an `AppIntentsPackage` in both the app and the
extension:

```swift
struct AppIntentsBundle: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [KitoWidgetsIntents.self] }
}
```

App Shortcuts must be declared with an `AppShortcutsProvider` in the app target,
not in a package.
