# ``KitoWidgets``

Home Screen and Lock Screen widget views with the App Intents and App Group plumbing behind them.

## Overview

KitoWidgets provides widget views ready to drop into a widget extension: stats
with sparklines, activity-style rings, self-ticking countdowns, interactive
to-do lists and counters, gauges, quotes and photos, weather, balances and quick
actions. Each view reads `widgetFamily` and has a layout for every family it
supports, renders vibrant on the Lock Screen, and works in StandBy and in light
and dark mode.

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
                               symbol: "figure.walk", tint: .mint)
        }
        .configurationDisplayName("Steps")
        .supportedFamilies(KitoStatWidgetView.supportedFamilies)
    }
}
```

Widgets can't read your app's theme, so each view takes its colours directly: a
`tint` and a ``KitoWidgetGradient`` background. Backgrounds go through
`containerBackground(for: .widget)`, so the system can remove them in StandBy and
on the tinted Home Screen. Your own widget views can use the same helper through
the `kitoWidgetBackground` modifier.

``KitoWidgetStore`` shares `Codable` values between the app and the extension
through an App Group, and the bundled intents let list and counter widgets
update without opening the app. ``KitoWidgetPreviewFrame`` renders any widget
view at a family's real size inside your app, for galleries and onboarding.

## Topics

### Essentials

- <doc:SharingDataAndIntents>
- ``KitoWidgets/KitoWidgets``

### Widget Views

- ``KitoStatWidgetView``
- ``KitoProgressRingWidgetView``
- ``KitoCountdownWidgetView``
- ``KitoListWidgetView``
- ``KitoCounterWidgetView``
- ``KitoGaugeWidgetView``
- ``KitoQuoteWidgetView``
- ``KitoPhotoWidgetView``
- ``KitoWeatherStyleWidgetView``
- ``KitoBalanceWidgetView``
- ``KitoQuickActionsWidgetView``

### Models

- ``KitoRing``
- ``KitoWidgetTask``
- ``KitoWidgetCounter``
- ``KitoHourlyForecast``
- ``KitoBalanceTransaction``
- ``KitoQuickAction``

### Timelines and Storage

- ``KitoWidgetEntry``
- ``KitoTimeline``
- ``KitoIntervalTimelineProvider``
- ``KitoWidgetStore``

### App Intents

- ``KitoWidgetsIntents``
- ``KitoToggleTaskIntent``
- ``KitoIncrementCounterIntent``
- ``KitoOpenDeepLinkIntent``
- ``KitoOpenShortcutIntent``
- ``KitoShortcutItem``
- ``KitoShortcutItemQuery``

### Styling and Previews

- ``KitoWidgetGradient``
- ``KitoWidgetBackground``
- ``KitoSparklineShape``
- ``KitoWidgetPreviewFrame``
- ``KitoWidgetPlacement``
- ``KitoWidgetMetrics``
- ``KitoLockScreenWallpaper``

### Calculations

- ``KitoProgress``
- ``KitoSparkline``
- ``KitoStatDelta``
- ``KitoStatFormat``
- ``KitoCountdown``
- ``KitoCountdownPhase``
