# KitoWidgets

**[Documentation](https://wyksofts-inc.github.io/KitoWidgets/documentation/kitowidgets/)**

Home Screen and Lock Screen widgets for SwiftUI, ready to drop into a widget extension: stats with
sparklines, Activity-style rings, self-ticking countdowns, interactive to-do lists and counters,
gauges, quotes and photos, weather, balances and quick actions. Each view has a layout for every family it
supports, renders vibrant on the Lock Screen, works in StandBy and light/dark, and comes with the
App Intents and App Group plumbing behind it. Part of the
[Kito](https://github.com/WykSofts-Inc/KitoDevKit) ecosystem.

## One widget, every size

```swift
import WidgetKit
import SwiftUI
import KitoWidgets

struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Steps", provider: KitoIntervalTimelineProvider(
            placeholder: KitoWidgetEntry(date: .now, value: 8_432.0)
        ) { date in
            KitoWidgetEntry(date: date, value: KitoWidgetStore.shared.load(Double.self, forKey: "steps", default: 0))
        }) { entry in
            KitoStatWidgetView(title: "Steps", value: entry.value, previous: 7_510,
                               history: [6_200, 7_400, 5_100, 8_900, 7_600, 9_800, entry.value],
                               symbol: "figure.walk", tint: .mint)
        }
        .configurationDisplayName("Steps")
        .supportedFamilies(KitoStatWidgetView.supportedFamilies)
    }
}
```

The view reads `widgetFamily` and switches layout: small, medium and large on the Home Screen;
circular, rectangular and inline on the Lock Screen. Backgrounds go through
`containerBackground(for: .widget)`, so the system can remove them in StandBy and the tinted Home
Screen; key shapes are `widgetAccentable()`.

## The widgets

| View | What it shows | Families |
| --- | --- | --- |
| `KitoStatWidgetView` | A big number, its change and a sparkline | all six |
| `KitoProgressRingWidgetView` | Up to four goal rings, with a second lap past the goal | all six |
| `KitoCountdownWidgetView` | Days, then a live timer, then "Happening now" — no reloads | all six |
| `KitoListWidgetView` | Tasks with tappable checks, or an agenda | all six |
| `KitoCounterWidgetView` | A daily counter with a "+" button, e.g. glasses of water | all six |
| `KitoGaugeWidgetView` | A value on a 270° gradient arc | all six |
| `KitoQuoteWidgetView` | A serif quote on a gradient or a photo | system, rectangular, inline |
| `KitoPhotoWidgetView` | A full-bleed photo with a caption over a scrim | system |
| `KitoWeatherStyleWidgetView` | Conditions with an hourly strip | all six |
| `KitoBalanceWidgetView` | A balance that hides itself when it should | all six |
| `KitoQuickActionsWidgetView` | A grid of intent and deep-link tiles | system, circular |

Widgets can't read your app's theme, so each one takes its colours: a `tint` and a
`KitoWidgetGradient` background (`.midnight`, `.sunset`, `.ocean`, `.aurora`, `.mint`, `.ember`,
`.grape`, `.blossom`, `.graphite`, or `.system`, which follows light and dark).

```swift
KitoProgressRingWidgetView(rings: [
    KitoRing(title: "Move", value: 420, goal: 600, unit: "kcal", color: .pink, symbol: "flame.fill"),
    KitoRing(title: "Exercise", value: 38, goal: 30, unit: "min", color: .green, symbol: "figure.run"),
    KitoRing(title: "Stand", value: 9, goal: 12, unit: "hr", color: .cyan, symbol: "figure.stand"),
], caption: "Close your rings by 9 pm")

KitoCountdownWidgetView(title: "Launch", target: launch, start: announced, now: entry.date)

KitoGaugeWidgetView(title: "Air quality", value: 72, in: 0...200, symbol: "aqi.medium", caption: "Moderate")

KitoBalanceWidgetView(title: "Everyday", balance: 124_480.5, currencyCode: "KES", change: 2_300,
                      history: month, accountSuffix: "4821", transactions: recent)
```

Your own widget can use the same background helper:

```swift
MyWidgetView().kitoWidgetBackground(.aurora)
MyWidgetView().kitoWidgetBackground { Image("coast").resizable().scaledToFill() }
```

## Countdowns that tick on their own

`KitoCountdownWidgetView` uses `Text(date, style: .relative)`, `Text(timerInterval:)` and
`ProgressView(timerInterval:)`, which the system redraws every second. Give the timeline an entry
at each phase change and nothing else:

```swift
let dates = [Date.now] + KitoCountdown.transitionDates(after: .now, target: launch)
let timeline = Timeline(entries: dates.map { KitoWidgetEntry(date: $0, value: launch) }, policy: .never)
```

## Interactive widgets (iOS 17)

`KitoListWidgetView` draws each check as `Toggle(isOn:intent:)` running `KitoToggleTaskIntent`, so
tasks tick off without opening the app. Save the list where the intent looks for it:

```swift
try KitoWidgetStore.shared.save(tasks, forKey: KitoWidgetTask.defaultStoreKey)
KitoWidgetStore.reloadTimelines(ofKind: "Tasks")
```

`KitoCounterWidgetView` does the same with a "+" button running `KitoIncrementCounterIntent`, and
your own buttons work the same way:

```swift
KitoCounterWidgetView(title: "Water", counter: entry.value, counterKey: "water")

Button(intent: KitoIncrementCounterIntent(counterKey: "water")) {
    Label("Log a glass", systemImage: "drop.fill")
}
```

The intents in the package:

- `KitoToggleTaskIntent(taskID:listKey:)` — flips a `KitoWidgetTask` in a saved list.
- `KitoIncrementCounterIntent(counterKey:amount:)` — adds to a daily `KitoWidgetCounter`, which
  starts again at zero each day.
- `KitoOpenDeepLinkIntent(url:)` — opens the app and leaves a URL for
  `KitoWidgetStore.shared.consumePendingDeepLink()`.
- `KitoOpenShortcutIntent` with `KitoShortcutItem`, an example `AppEntity` and `EntityStringQuery`
  that Siri, Shortcuts and Spotlight can list.

Register them in both the app and the extension:

```swift
struct AppIntentsBundle: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [KitoWidgetsIntents.self] }
}
```

App Shortcuts have to be declared in the app target, not a package:

```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: KitoIncrementCounterIntent(), phrases: [
            "Log a glass of water in \(.applicationName)",
        ], shortTitle: "Log water", systemImageName: "drop.fill")
        AppShortcut(intent: KitoOpenShortcutIntent(), phrases: [
            "Open \(\.$item) in \(.applicationName)",
        ], shortTitle: "Open", systemImageName: "arrow.up.forward.app")
    }
}
```

## Sharing data with the extension

`KitoWidgetStore` reads and writes `Codable` values in an App Group's `UserDefaults`:

```swift
let store = KitoWidgetStore(appGroup: "group.com.example.app")
try store.save(balance, forKey: "balance")
let saved = store.load(Balance.self, forKey: "balance")
try store.update(KitoWidgetCounter.self, forKey: "water", default: KitoWidgetCounter()) { $0.increment() }
KitoWidgetStore.reloadTimelines(ofKind: "Balance")   // or nil for every widget
```

`KitoWidgetStore.shared` — the store the intents use — takes its App Group from the
`KitoWidgetsAppGroup` Info.plist key, so set that key (and the App Groups entitlement) in both the
app and the extension. Without it, it falls back to standard defaults, which is fine for in-app
previews but not shared with the widget.

## Timelines

```swift
KitoTimeline.dates(from: .now, every: 15 * 60, count: 4, aligned: true)   // on the quarter hour
KitoTimeline.timeline(from: .now, every: 3_600, count: 6) { KitoWidgetEntry(date: $0, value: forecast(at: $0)) }
KitoIntervalTimelineProvider(placeholder: entry, interval: 900) { date in makeEntry(date) }
```

## Showing widgets inside your app

`KitoWidgetPreviewFrame` renders any widget view at a family's real point size, margins and corner
radius — Lock Screen families on a wallpaper, rendered vibrant — for galleries, onboarding and
"add our widget" screens:

```swift
KitoWidgetPreviewFrame(.systemMedium, showsLabel: true) {
    KitoStatWidgetView(title: "Steps", value: steps, previous: 7_510, history: week)
}
KitoWidgetPreviewFrame(.systemSmall, placement: .standBy) { … }
KitoWidgetPreviewFrame(.accessoryRectangular) { … }
```

Inside a preview frame, interactive rows use `Button(intent:)`, which runs the intent in your app;
`KitoWidgetStore.didChangeNotification` tells you when to reload. `KitoListWidgetView` also takes an
`onToggle` closure for in-app use.

## Building blocks

- `KitoProgress` — clamped fractions, second-lap ratios, round-down percentages.
- `KitoSparkline` and `KitoSparklineShape` — normalised points and a smooth line or area.
- `KitoStatDelta` and `KitoStatFormat` — change, direction, and number/percent/currency/compact text.
- `KitoCountdown` — phases, transition dates, day counts and short remaining text.
- `KitoWidgetMetrics` — each family's size, corner radius and margin.

## Installation

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoWidgets.git", from: "0.1.0")
```

Add `KitoWidgets` to both your app target and your widget extension target. The package only uses
APIs available to app extensions.

## License

MIT — see [LICENSE](LICENSE).
