//
//  KitoWeatherStyleWidgetView.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Current conditions with an hourly strip, in the style of Weather. Bring your own data.
///
/// ```swift
/// KitoWeatherStyleWidgetView(location: "Nairobi", temperature: 24, condition: "Partly Cloudy",
///                            symbol: "cloud.sun.fill", high: 26, low: 14, hourly: hours)
/// ```
public struct KitoWeatherStyleWidgetView: View {
    /// The families this view has a layout for.
    public static let supportedFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]

    let location: String
    let temperature: Double
    let condition: String
    let symbol: String
    let high: Double
    let low: Double
    let hourly: [KitoHourlyForecast]
    let background: KitoWidgetGradient
    private var traits = KitoWidgetTraits()

    /// - Parameters:
    ///   - location: The place name.
    ///   - temperature: Now, in whatever unit you show.
    ///   - condition: E.g. "Partly Cloudy".
    ///   - symbol: An SF Symbol, e.g. "cloud.sun.fill". Drawn in multicolour.
    ///   - high: Today's high.
    ///   - low: Today's low.
    ///   - hourly: The coming hours, soonest first. The first one is labelled "Now".
    ///   - background: The sky. Try `.ocean` by day and `.midnight` at night.
    public init(location: String, temperature: Double, condition: String, symbol: String, high: Double, low: Double,
                hourly: [KitoHourlyForecast] = [], background: KitoWidgetGradient = .ocean) {
        self.location = location
        self.temperature = temperature
        self.condition = condition
        self.symbol = symbol
        self.high = high
        self.low = low
        self.hourly = hourly
        self.background = background
    }

    private var foreground: Color { traits.showsBackground ? background.foreground : .primary }

    private func degrees(_ value: Double) -> String {
        guard value.isFinite else { return "--°" }
        return "\(Int(value.rounded()))°"
    }

    public var body: some View {
        content
            .kitoWidgetBackground(background)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(location), \(degrees(temperature)), \(condition)"))
            .accessibilityValue(Text("High \(degrees(high)), low \(degrees(low))"))
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

    // MARK: Pieces

    private var place: some View {
        HStack(spacing: 3) {
            Text(location).font(.system(size: 14, weight: .semibold))
            Image(systemName: "location.fill").font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(foreground)
        .lineLimit(1)
    }

    private func bigTemperature(_ size: CGFloat) -> some View {
        Text(degrees(temperature))
            .font(.system(size: size, weight: .light, design: .rounded))
            .foregroundStyle(foreground)
            .contentTransition(.numericText(value: temperature))
            .animation(.snappy, value: temperature)
    }

    private var weatherSymbol: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.multicolor)
            .font(.system(size: 20))
            .widgetAccentable()
    }

    private var highLow: some View {
        Text("H:\(degrees(high))  L:\(degrees(low))")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
    }

    private func hourLabel(_ item: KitoHourlyForecast, index: Int) -> String {
        index == 0 ? "Now" : item.date.formatted(.dateTime.hour())
    }

    private func strip(count: Int, showsRain: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(hourly.prefix(count).enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 5) {
                    Text(hourLabel(item, index: index))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(foreground.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: item.symbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 16))
                        .frame(height: 20)
                        .overlay(alignment: .bottom) {
                            if showsRain && item.precipitationChance > 0.2 {
                                Text(KitoProgress.percentText(item.precipitationChance))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 1))
                                    .fixedSize()
                                    .offset(y: 11)
                            }
                        }
                        .padding(.bottom, showsRain ? 8 : 0)
                    Text(degrees(item.temperature))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(foreground)
                        .contentTransition(.numericText(value: item.temperature))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            place
            bigTemperature(44)
            Spacer(minLength: 0)
            weatherSymbol.padding(.bottom, 2)
            Text(condition)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
            highLow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                place
                bigTemperature(traits.family == .systemMedium ? 34 : 40)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                weatherSymbol
                Text(condition)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                highLow
            }
        }
    }

    private var medium: some View {
        VStack(spacing: 8) {
            summaryRow
            Spacer(minLength: 0)
            strip(count: 6, showsRain: false)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryRow
            strip(count: 6, showsRain: true)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(foreground.opacity(0.1)))
            Text("NEXT \(min(hourly.count, 12)) HOURS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(foreground.opacity(0.6))
            let temps = hourly.prefix(12).map(\.temperature)
            ZStack(alignment: .bottom) {
                KitoSparklineView(values: temps, tint: .white, lineWidth: 2.4)
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(hourly.prefix(12)) { item in
                        Capsule()
                            .fill(Color(red: 0.55, green: 0.85, blue: 1).opacity(0.7))
                            .frame(width: 6, height: max(3, 30 * item.precipitationChance))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 30)
                .opacity(0.8)
            }
            .frame(maxHeight: .infinity)
            .animation(.smooth, value: temps)
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        Gauge(value: temperature, in: min(low, temperature)...max(high, temperature, low + 1)) {
            Image(systemName: symbol)
        } currentValueLabel: {
            Text(degrees(temperature)).font(.system(size: 17, weight: .semibold, design: .rounded))
        } minimumValueLabel: {
            Text("\(Int(low.rounded()))")
        } maximumValueLabel: {
            Text("\(Int(high.rounded()))")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 26))
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text("\(degrees(temperature)) \(condition)")
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("H:\(degrees(high)) L:\(degrees(low))").font(.system(size: 12, weight: .medium)).opacity(0.8)
                Text(location).font(.system(size: 12, weight: .medium)).opacity(0.65).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label("\(degrees(temperature)) \(condition)", systemImage: symbol)
    }
}
