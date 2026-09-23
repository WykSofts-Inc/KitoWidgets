//
//  KitoGaugeWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A reading on a scale — air quality, battery, budget used — as a 270° gradient arc.
///
/// ```swift
/// KitoGaugeWidgetView(title: "Air quality", value: 42, in: 0...300, caption: "Good")
/// ```
public struct KitoGaugeWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let format: KitoStatFormat
    let symbol: String
    let caption: String?
    let detail: String?
    let colors: [Color]
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - title: What's measured.
    ///   - value: The reading.
    ///   - range: The scale. The value is clamped to it for drawing.
    ///   - format: How numbers are written.
    ///   - symbol: An SF Symbol for the header and Lock Screen.
    ///   - caption: A status under the number, e.g. "Good".
    ///   - detail: A sentence for the medium and large sizes.
    ///   - colors: The arc's gradient, low to high.
    ///   - background: The gradient behind it.
    public init(title: String, value: Double, in range: ClosedRange<Double> = 0...100, format: KitoStatFormat = .number(),
                symbol: String = "gauge.with.dots.needle.67percent", caption: String? = nil, detail: String? = nil,
                colors: [Color] = [.green, .yellow, .orange, .red], background: KitoWidgetGradient = .graphite) {
        self.title = title
        self.value = value
        self.range = range
        self.format = format
        self.symbol = symbol
        self.caption = caption
        self.detail = detail
        self.colors = colors.isEmpty ? [.white] : colors
        self.background = background
    }

    private var fraction: Double { KitoProgress.fraction(value, in: range) }
    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }
    private var valueText: String { format.string(for: value) }
    /// The gradient colour under the current value.
    private var currentColor: Color {
        let index = Int((fraction * Double(colors.count - 1)).rounded())
        return colors[min(max(index, 0), colors.count - 1)]
    }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text([valueText, caption].compactMap { $0 }.joined(separator: ", ")))
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

    private func dial(lineWidth: CGFloat, valueSize: CGFloat) -> some View {
        KitoArcGauge(fraction: fraction, colors: colors, lineWidth: lineWidth, foreground: foreground)
            .overlay {
                VStack(spacing: 0) {
                    Text(valueText)
                        .font(.system(size: valueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText(value: value))
                        .animation(.snappy, value: value)
                    if let caption {
                        Text(caption)
                            .font(.system(size: valueSize * 0.36, weight: .bold))
                            .foregroundStyle(currentColor)
                            .lineLimit(1)
                            .widgetAccentable()
                    }
                }
                .padding(.horizontal, lineWidth * 1.6)
            }
    }

    private var scaleLabels: some View {
        HStack {
            Text(format.string(for: range.lowerBound))
            Spacer()
            Text(format.string(for: range.upperBound))
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .foregroundStyle(foreground.opacity(0.5))
    }

    private var small: some View {
        VStack(spacing: 2) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: currentColor, foreground: foreground)
            dial(lineWidth: 11, valueSize: 26)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 6)
            scaleLabels.padding(.horizontal, 14).padding(.top, -14)
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(spacing: 0) {
                dial(lineWidth: 12, valueSize: 28)
                scaleLabels.padding(.horizontal, 12).padding(.top, -12)
            }
            .frame(width: 128)
            VStack(alignment: .leading, spacing: 6) {
                KitoWidgetHeader(symbol: symbol, title: title, tint: currentColor, foreground: foreground)
                Spacer(minLength: 0)
                if let caption {
                    Text(caption)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(foreground.opacity(0.65))
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
                scaleBar
            }
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            KitoWidgetHeader(symbol: symbol, title: title, tint: currentColor, foreground: foreground)
            dial(lineWidth: 18, valueSize: 46)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 30)
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(foreground.opacity(0.7))
                    .lineLimit(2)
            }
            scaleBar
            scaleLabels
        }
    }

    /// A flat gradient bar with a marker at the value.
    private var scaleBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(height: 6)
                    .widgetAccentable()
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .offset(x: (proxy.size.width - 12) * fraction)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 12)
    }

    // MARK: Lock Screen

    private var circular: some View {
        Gauge(value: fraction) {
            Image(systemName: symbol)
        } currentValueLabel: {
            Text(KitoStatFormat.compact.string(for: value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Gradient(colors: colors))
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .widgetAccentable()
                Spacer(minLength: 2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(valueText).font(.system(size: 22, weight: .bold, design: .rounded))
                if let caption { Text(caption).font(.system(size: 13, weight: .semibold)).opacity(0.8) }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Gauge(value: fraction) { EmptyView() }
                .gaugeStyle(.accessoryLinear)
                .tint(Gradient(colors: colors))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label("\(title) \(valueText)\(caption.map { " · \($0)" } ?? "")", systemImage: symbol)
    }
}

/// A 270° arc with a gradient track and a knob at the value.
struct KitoArcGauge: View {
    let fraction: Double
    let colors: [Color]
    let lineWidth: CGFloat
    let foreground: Color

    private static let sweep = 0.75

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let radius = (side - lineWidth) / 2
            let angle = Angle.degrees(135 + 270 * fraction)
            let gradient = AngularGradient(colors: colors, center: .center, startAngle: .degrees(0), endAngle: .degrees(270))
            ZStack {
                Circle()
                    .trim(from: 0, to: Self.sweep)
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .opacity(0.25)
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: Self.sweep * max(fraction, 0.001))
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .widgetAccentable()
                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.9, height: lineWidth * 0.9)
                    .shadow(color: .black.opacity(0.35), radius: 2)
                    .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
            }
            .frame(width: side - lineWidth, height: side - lineWidth)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
