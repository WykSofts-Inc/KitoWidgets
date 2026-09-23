//
//  KitoProgressRingWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Concentric goal rings, like Activity. Rings past their goal keep going for a second lap.
///
/// ```swift
/// KitoProgressRingWidgetView(rings: [
///     KitoRing(title: "Move", value: 420, goal: 600, unit: "kcal", color: .pink),
///     KitoRing(title: "Exercise", value: 18, goal: 30, unit: "min", color: .green),
///     KitoRing(title: "Stand", value: 9, goal: 12, unit: "hr", color: .cyan),
/// ])
/// ```
public struct KitoProgressRingWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let rings: [KitoRing]
    let caption: String?
    let symbol: String
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: The header, e.g. "Activity".
    ///   - rings: Outermost first. Up to four are drawn.
    ///   - caption: A line in the large size, e.g. "Close your rings by 9 pm".
    ///   - symbol: An SF Symbol for the header.
    ///   - background: The gradient behind it.
    public init(title: String = "Activity", rings: [KitoRing], caption: String? = nil, symbol: String = "flame.fill",
                background: KitoWidgetGradient = .midnight) {
        self.title = title
        self.rings = Array(rings.prefix(4))
        self.caption = caption
        self.symbol = symbol
        self.background = background
    }

    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var headerTint: Color { rings.first?.color ?? .pink }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(rings.map { "\($0.title) \(KitoProgress.percentText($0.progress))" }.joined(separator: ", ")))
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

    /// Rings nested inside `size`, outermost first.
    private func ringStack(size: CGFloat, lineWidth: CGFloat, gap: CGFloat, trackOpacity: Double = 0.22) -> some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                let inset = CGFloat(index) * (lineWidth + gap) * 2
                KitoRingView(laps: ring.laps, color: ring.color, lineWidth: lineWidth, trackOpacity: trackOpacity)
                    .frame(width: max(size - inset, lineWidth), height: max(size - inset, lineWidth))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: ring.laps)
            }
        }
        .frame(width: size, height: size)
    }

    private func amount(_ ring: KitoRing) -> String {
        let value = KitoStatFormat.number().string(for: ring.value)
        let goal = KitoStatFormat.number().string(for: ring.goal)
        return ring.unit.isEmpty ? "\(value)/\(goal)" : "\(value)/\(goal) \(ring.unit.uppercased())"
    }

    private var small: some View {
        VStack(spacing: 8) {
            ringStack(size: 94, lineWidth: 12, gap: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                ForEach(rings) { ring in
                    Text(KitoProgress.percentText(ring.progress))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(ring.color)
                        .contentTransition(.numericText(value: ring.progress))
                        .widgetAccentable()
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            ringStack(size: 122, lineWidth: 14, gap: 2)
            VStack(alignment: .leading, spacing: 6) {
                KitoWidgetHeader(symbol: symbol, title: title, tint: headerTint, foreground: foreground)
                Spacer(minLength: 0)
                ForEach(rings) { ring in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(ring.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ring.color)
                            .widgetAccentable()
                        Text(amount(ring))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(foreground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .contentTransition(.numericText(value: ring.value))
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 14) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: headerTint, foreground: foreground)
            ringStack(size: 170, lineWidth: 20, gap: 3)
                .frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                ForEach(rings) { ring in
                    HStack(spacing: 10) {
                        Image(systemName: ring.symbol ?? "circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ring.color)
                            .frame(width: 18)
                            .widgetAccentable()
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ring.title).font(.subheadline.weight(.semibold)).foregroundStyle(foreground)
                                Spacer()
                                Text(amount(ring))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(foreground.opacity(0.7))
                                    .contentTransition(.numericText(value: ring.value))
                            }
                            KitoProgressBar(fraction: ring.progress, color: ring.color)
                        }
                    }
                }
            }
            if let caption {
                Text(caption).font(.caption).foregroundStyle(foreground.opacity(0.6)).lineLimit(1)
            }
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            KitoAccessoryBackdrop()
            ringStack(size: 62, lineWidth: rings.count > 2 ? 6 : 8, gap: 1.5, trackOpacity: 0.28)
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            ringStack(size: 52, lineWidth: rings.count > 2 ? 5.5 : 7, gap: 1.5, trackOpacity: 0.28)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(rings.prefix(3)) { ring in
                    HStack(spacing: 4) {
                        Text(ring.title).font(.system(size: 12, weight: .medium)).opacity(0.8)
                        Spacer(minLength: 2)
                        Text(KitoProgress.percentText(ring.progress))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .widgetAccentable()
                    }
                    .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            Text(rings.prefix(2).map { "\($0.title) \(KitoProgress.percentText($0.progress))" }.joined(separator: " · "))
        } icon: {
            Image(systemName: symbol)
        }
    }
}

/// A thin capsule progress bar.
struct KitoProgressBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.22))
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.75), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(proxy.size.width * min(max(fraction, 0), 1), height))
                    .widgetAccentable()
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)
    }
}
