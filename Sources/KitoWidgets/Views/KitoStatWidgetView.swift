//
//  KitoStatWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A big number with its change and a sparkline — steps, revenue, sign-ups.
///
/// ```swift
/// KitoStatWidgetView(title: "Steps", value: 8_432, previous: 7_510, history: week,
///                    symbol: "figure.walk", tint: .mint)
/// ```
///
/// Supports every family in ``supportedFamilies``, including the three Lock Screen ones.
public struct KitoStatWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let value: Double
    let previous: Double?
    let history: [Double]
    let format: KitoStatFormat
    let symbol: String
    let tint: Color
    let caption: String?
    let increaseIsGood: Bool
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: What's measured, e.g. "Steps".
    ///   - value: The current reading.
    ///   - previous: The reading to compare with; draws the change badge.
    ///   - history: Recent readings, oldest first, for the sparkline.
    ///   - format: How the number is written.
    ///   - symbol: An SF Symbol for the header.
    ///   - tint: The sparkline and symbol colour.
    ///   - caption: A line under the number, e.g. "vs. yesterday".
    ///   - increaseIsGood: Pass `false` for stats like spending, so a rise shows red.
    ///   - background: The gradient behind it.
    public init(title: String, value: Double, previous: Double? = nil, history: [Double] = [],
                format: KitoStatFormat = .number(), symbol: String = "chart.line.uptrend.xyaxis", tint: Color = .mint,
                caption: String? = nil, increaseIsGood: Bool = true, background: KitoWidgetGradient = .midnight) {
        self.title = title
        self.value = value
        self.previous = previous
        self.history = history
        self.format = format
        self.symbol = symbol
        self.tint = tint
        self.caption = caption
        self.increaseIsGood = increaseIsGood
        self.background = background
    }

    private var delta: KitoStatDelta? { previous.map { KitoStatDelta(current: value, previous: $0) } }
    private var valueText: String { format.string(for: value) }
    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var series: [Double] { history.isEmpty ? [] : history }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(title), \(valueText)"))
            .accessibilityValue(Text(delta.map { "\($0.text(format: format)) \(caption ?? "")" } ?? ""))
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

    private func number(size: CGFloat) -> some View {
        Text(valueText)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(value: value))
            .animation(.snappy, value: value)
    }

    @ViewBuilder private var badge: some View {
        if let delta {
            KitoDeltaBadge(delta: delta, increaseIsGood: increaseIsGood, format: format)
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground)
            Spacer(minLength: 4)
            number(size: 34)
            HStack(spacing: 6) {
                badge
                if let caption, delta == nil {
                    Text(caption).font(.caption2).foregroundStyle(foreground.opacity(0.6)).lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if !series.isEmpty {
                KitoSparklineView(values: series, tint: tint, lineWidth: 2.2)
                    .frame(height: 34)
                    .animation(.smooth, value: series)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground)
                Spacer(minLength: 0)
                number(size: 38)
                badge
                if let caption {
                    Text(caption).font(.caption2).foregroundStyle(foreground.opacity(0.6)).lineLimit(1)
                }
            }
            .frame(width: 128, alignment: .leading)
            KitoSparklineView(values: series, tint: tint, lineWidth: 2.8)
                .padding(.vertical, 6)
                .animation(.smooth, value: series)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: tint, foreground: foreground, trailing: caption)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                number(size: 50)
                badge
                Spacer(minLength: 0)
            }
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        if index > 0 { Spacer() }
                        Rectangle()
                            .fill(foreground.opacity(0.12))
                            .frame(height: 1)
                    }
                }
                KitoSparklineView(values: series, tint: tint, lineWidth: 3.2)
                    .animation(.smooth, value: series)
            }
            .frame(maxHeight: .infinity)
            if let summary = KitoSparkline.summary(series) {
                HStack(spacing: 8) {
                    summaryTile("Low", summary.min)
                    summaryTile("Average", summary.average)
                    summaryTile("High", summary.max)
                }
            }
        }
    }

    private func summaryTile(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(foreground.opacity(0.55))
            Text(format.string(for: value))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText(value: value))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(foreground.opacity(0.08)))
    }

    // MARK: Lock Screen

    private var compactValue: String {
        KitoStatFormat.compact.string(for: value)
    }

    private var circular: some View {
        ZStack {
            KitoAccessoryBackdrop()
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .widgetAccentable()
                Text(compactValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText(value: value))
                if let delta {
                    Image(systemName: delta.direction == .up ? "arrow.up" : delta.direction == .down ? "arrow.down" : "equal")
                        .font(.system(size: 9, weight: .heavy))
                }
            }
            .padding(6)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .widgetAccentable()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: value))
                if let delta {
                    Text(delta.text(format: format)).font(.system(size: 12, weight: .semibold)).opacity(0.8)
                }
            }
            if !series.isEmpty {
                KitoSparklineView(values: series, tint: .white, lineWidth: 1.6, showsFill: false, showsDot: false)
                    .frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            Text("\(title) \(compactValue)\(delta.map { " \($0.text(format: format))" } ?? "")")
        } icon: {
            Image(systemName: symbol)
        }
    }
}
