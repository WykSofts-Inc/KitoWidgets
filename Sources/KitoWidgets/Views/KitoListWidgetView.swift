//
//  KitoListWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Tasks you can tick off right on the Home Screen, or an agenda of what's next.
///
/// In a widget each check is a `Toggle(isOn:intent:)` running ``KitoToggleTaskIntent`` against
/// the list saved under `storeKey` in ``KitoWidgetStore/shared``; the system flips it instantly
/// and reloads the widget once the intent finishes.
///
/// ```swift
/// KitoListWidgetView(title: "Today", items: entry.value)
/// ```
public struct KitoListWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    /// How rows are drawn.
    public enum Style: Hashable, Sendable {
        /// A check you can tap on every row.
        case checklist
        /// A time and a coloured bar instead of a check, for calendars and schedules.
        case agenda
    }

    let title: String
    let items: [KitoWidgetTask]
    let style: Style
    let storeKey: String
    let symbol: String
    let tint: Color
    let background: KitoWidgetGradient
    let onToggle: ((KitoWidgetTask) -> Void)?
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: The header, e.g. "Today".
    ///   - items: The tasks, in display order.
    ///   - style: Checklist (default) or agenda.
    ///   - storeKey: Where the toggle intent finds this list.
    ///   - symbol: An SF Symbol for the header.
    ///   - tint: The check and accent colour.
    ///   - background: The gradient behind it. `.system` looks like Reminders.
    ///   - onToggle: In-app only: handle taps yourself instead of running the intent. Widgets
    ///     can't run closures, so leave it `nil` there.
    public init(title: String = "Today", items: [KitoWidgetTask], style: Style = .checklist,
                storeKey: String = KitoWidgetTask.defaultStoreKey, symbol: String = "checklist", tint: Color = .blue,
                background: KitoWidgetGradient = .system, onToggle: ((KitoWidgetTask) -> Void)? = nil) {
        self.title = title
        self.items = items
        self.style = style
        self.storeKey = storeKey
        self.symbol = symbol
        self.tint = tint
        self.background = background
        self.onToggle = onToggle
    }

    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var remaining: Int { items.count - items.completedCount }
    private var remainingText: String {
        switch style {
        case .checklist: return remaining == 0 ? "All done" : "\(remaining) left"
        case .agenda: return "\(items.count) \(items.count == 1 ? "event" : "events")"
        }
    }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title), \(remainingText)"))
    }

    @ViewBuilder private var content: some View {
        switch traits.family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        case .systemLarge, .systemExtraLarge: large
        default: small
        }
    }

    // MARK: Rows

    @ViewBuilder private func row(_ task: KitoWidgetTask, showsDetail: Bool) -> some View {
        switch style {
        case .agenda:
            agendaRow(task, showsDetail: showsDetail)
        case .checklist:
            if let onToggle {
                Button { onToggle(task) } label: { checkRow(task, isOn: task.isDone, showsDetail: showsDetail) }
                    .buttonStyle(.plain)
            } else if traits.isPreview {
                // Outside a widget `Button(intent:)` just runs the intent, which a preview can show.
                Button(intent: KitoToggleTaskIntent(taskID: task.id, listKey: storeKey)) {
                    checkRow(task, isOn: task.isDone, showsDetail: showsDetail)
                }
                .buttonStyle(.plain)
            } else {
                Toggle(isOn: task.isDone, intent: KitoToggleTaskIntent(taskID: task.id, listKey: storeKey)) {
                    rowText(task, isOn: task.isDone, showsDetail: showsDetail)
                }
                .toggleStyle(KitoCheckToggleStyle(tint: tint, foreground: foreground))
            }
        }
    }

    private func checkRow(_ task: KitoWidgetTask, isOn: Bool, showsDetail: Bool) -> some View {
        HStack(spacing: 9) {
            KitoCheckmark(isOn: isOn, tint: tint, foreground: foreground)
            rowText(task, isOn: isOn, showsDetail: showsDetail)
        }
        .contentShape(Rectangle())
    }

    private func rowText(_ task: KitoWidgetTask, isOn: Bool, showsDetail: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .strikethrough(isOn, color: foreground.opacity(0.5))
                .foregroundStyle(foreground.opacity(isOn ? 0.45 : 1))
                .lineLimit(1)
            if showsDetail, let detail = task.detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(foreground.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(isOn ? "Done" : "Not done"))
        .invalidatableContent()
    }

    private func agendaRow(_ task: KitoWidgetTask, showsDetail: Bool) -> some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(task.isDone ? foreground.opacity(0.25) : tint)
                .frame(width: 4)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(foreground.opacity(task.isDone ? 0.45 : 1))
                    .lineLimit(1)
                if let due = task.due {
                    Text(showsDetail && task.detail != nil ? "\(due.formatted(date: .omitted, time: .shortened)) · \(task.detail ?? "")" : due.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(foreground.opacity(0.55))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func header(trailing: Bool = true) -> some View {
        KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground, trailing: trailing ? remainingText : nil)
    }

    private func moreLabel(shown: Int) -> some View {
        Group {
            if items.count > shown {
                Text("+\(items.count - shown) more")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.5))
            }
        }
    }

    private var ordered: [KitoWidgetTask] { style == .checklist ? items.openFirst : items }
    private var smallCount: Int { style == .agenda ? 2 : 3 }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            header()
            if items.isEmpty {
                emptyState
            } else {
                ForEach(ordered.prefix(smallCount)) { task in row(task, showsDetail: false) }
                Spacer(minLength: 0)
                moreLabel(shown: smallCount)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .widgetAccentable()
                Spacer(minLength: 0)
                Text("\(style == .checklist ? remaining : items.count)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                    .contentTransition(.numericText(value: Double(remaining)))
                    .invalidatableContent()
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.7))
                    .lineLimit(1)
                if style == .checklist && !items.isEmpty {
                    KitoProgressBar(fraction: items.completionFraction, color: tint, height: 5)
                        .invalidatableContent()
                }
            }
            .frame(width: 88, alignment: .leading)
            VStack(alignment: .leading, spacing: 9) {
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(ordered.prefix(style == .agenda ? 3 : 4)) { task in row(task, showsDetail: false) }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            header()
            if style == .checklist && !items.isEmpty {
                KitoProgressBar(fraction: items.completionFraction, color: tint, height: 6)
                    .invalidatableContent()
            }
            if items.isEmpty {
                emptyState
            } else {
                ForEach(ordered.prefix(7)) { task in
                    row(task, showsDetail: true)
                    if task.id != ordered.prefix(7).last?.id {
                        Rectangle().fill(foreground.opacity(0.08)).frame(height: 1)
                    }
                }
                Spacer(minLength: 0)
                moreLabel(shown: 7)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint)
                .widgetAccentable()
            Text("Nothing left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(foreground.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            KitoAccessoryBackdrop()
            if style == .checklist {
                KitoRingView(laps: items.completionFraction, color: .white, lineWidth: 5, trackOpacity: 0.25)
                    .padding(4)
            }
            VStack(spacing: -2) {
                if style == .agenda {
                    Image(systemName: symbol).font(.system(size: 11, weight: .bold)).widgetAccentable()
                }
                Text("\(remaining)").font(.system(size: 22, weight: .bold, design: .rounded))
                Text(style == .agenda ? "NEXT" : "LEFT").font(.system(size: 8, weight: .heavy))
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .widgetAccentable()
            ForEach(ordered.filter { !$0.isDone }.prefix(2)) { task in
                HStack(spacing: 5) {
                    Image(systemName: style == .agenda ? "clock" : "circle").font(.system(size: 10, weight: .bold))
                    Text(task.title).font(.system(size: 13)).lineLimit(1)
                }
            }
            if remaining == 0 {
                Text("All done").font(.system(size: 13)).opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            if let next = ordered.first(where: { !$0.isDone }) {
                Text("\(remainingText) · \(next.title)")
            } else {
                Text("\(title): all done")
            }
        } icon: {
            Image(systemName: symbol)
        }
    }
}

/// A round check that fills when done.
struct KitoCheckmark: View {
    let isOn: Bool
    let tint: Color
    let foreground: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isOn ? tint : foreground.opacity(0.35), lineWidth: 1.6)
            if isOn {
                Circle().fill(tint)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 20, height: 20)
        .widgetAccentable()
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
    }
}

/// Draws a `Toggle` as a round check followed by its label. The widget handles the tap.
struct KitoCheckToggleStyle: ToggleStyle {
    let tint: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 9) {
            KitoCheckmark(isOn: configuration.isOn, tint: tint, foreground: foreground)
            configuration.label
        }
        .contentShape(Rectangle())
    }
}
