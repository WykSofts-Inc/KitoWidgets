//
//  KitoCounterWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A daily counter with a "+" button that logs one more right from the Home Screen — glasses of
/// water, cups of coffee, pages read. The button runs ``KitoIncrementCounterIntent`` against the
/// counter saved under `counterKey` in ``KitoWidgetStore/shared``.
///
/// ```swift
/// KitoCounterWidgetView(title: "Water", counter: entry.value, counterKey: "water")
/// ```
public struct KitoCounterWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let counter: KitoWidgetCounter
    let counterKey: String
    let symbol: String
    let tint: Color
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: What's counted, e.g. "Water".
    ///   - counter: The saved counter. It shows as zero once its day has passed.
    ///   - counterKey: Where the "+" intent finds the counter.
    ///   - symbol: An SF Symbol for one unit, e.g. "drop.fill".
    ///   - tint: The ring and button colour.
    ///   - background: The gradient behind it.
    ///   - now: The entry's date, for the daily reset.
    public init(title: String = "Water", counter: KitoWidgetCounter, counterKey: String = KitoWidgetCounter.defaultStoreKey,
                symbol: String = "drop.fill", tint: Color = .cyan, background: KitoWidgetGradient = .midnight, now: Date = Date()) {
        self.title = title
        self.counter = counter.current(at: now)
        self.counterKey = counterKey
        self.symbol = symbol
        self.tint = tint
        self.background = background
    }

    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var summary: String { "\(counter.count) of \(counter.goal) \(counter.unit)" }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title), \(summary)"))
    }

    @ViewBuilder private var content: some View {
        switch traits.family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: Label("\(counter.count)/\(counter.goal) \(counter.unit)", systemImage: symbol)
        case .systemMedium: medium
        case .systemLarge, .systemExtraLarge: large
        default: small
        }
    }

    // MARK: Pieces

    private func ring(size: CGFloat, lineWidth: CGFloat, countSize: CGFloat) -> some View {
        ZStack {
            KitoRingView(laps: counter.progress, color: tint, lineWidth: lineWidth, trackOpacity: 0.2)
            VStack(spacing: -2) {
                Image(systemName: counter.isComplete ? "checkmark" : symbol)
                    .font(.system(size: countSize * 0.4, weight: .bold))
                    .foregroundStyle(tint)
                    .contentTransition(.symbolEffect(.replace))
                    .widgetAccentable()
                Text("\(counter.count)")
                    .font(.system(size: countSize, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                    .contentTransition(.numericText(value: Double(counter.count)))
                    .invalidatableContent()
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: counter.count)
    }

    private func addButton(size: CGFloat) -> some View {
        Button(intent: KitoIncrementCounterIntent(counterKey: counterKey, amount: 1)) {
            Image(systemName: "plus")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(background.colors.last ?? .black)
                .frame(width: size, height: size)
                .background(Circle().fill(tint.gradient))
                .widgetAccentable()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Add one"))
    }

    private var undoButton: some View {
        Button(intent: KitoIncrementCounterIntent(counterKey: counterKey, amount: -1)) {
            Image(systemName: "minus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 34, height: 34)
                .background(Circle().fill(foreground.opacity(0.14)))
        }
        .buttonStyle(.plain)
        .disabled(counter.count == 0)
        .accessibilityLabel(Text("Remove one"))
    }

    /// One symbol per unit of the goal, filled up to the count.
    private func units(size: CGFloat, columns: Int) -> some View {
        let total = min(counter.goal, 12)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(size * 1.55), spacing: 3), count: min(columns, total)),
                         alignment: .leading, spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Image(systemName: symbol)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(index < counter.count ? tint : foreground.opacity(0.18))
                    .widgetAccentable(index < counter.count)
            }
        }
        .invalidatableContent()
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground)
            HStack(alignment: .bottom) {
                ring(size: 78, lineWidth: 9, countSize: 24)
                Spacer(minLength: 0)
                addButton(size: 40)
            }
            .frame(maxHeight: .infinity)
            Text("of \(counter.goal) \(counter.unit)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground.opacity(0.65))
                .lineLimit(1)
        }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            ring(size: 118, lineWidth: 13, countSize: 36)
            VStack(alignment: .leading, spacing: 8) {
                KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground)
                Text(counter.isComplete ? "Goal reached" : "\(counter.goal - counter.count) to go")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                    .contentTransition(.numericText(value: Double(counter.count)))
                units(size: 12, columns: 8)
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    undoButton
                    Spacer(minLength: 0)
                    addButton(size: 34)
                }
            }
        }
    }

    private var large: some View {
        VStack(spacing: 16) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground, trailing: summary)
            ring(size: 170, lineWidth: 18, countSize: 54)
                .frame(maxHeight: .infinity)
            units(size: 20, columns: 6)
            HStack(spacing: 12) {
                undoButton
                Button(intent: KitoIncrementCounterIntent(counterKey: counterKey, amount: 1)) {
                    Label("Add one", systemImage: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(background.colors.last ?? .black)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(tint.gradient))
                        .widgetAccentable()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        Gauge(value: counter.progress) {
            Image(systemName: symbol)
        } currentValueLabel: {
            Text("\(counter.count)").font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .widgetAccentable()
            Text(summary)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Gauge(value: counter.progress) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
