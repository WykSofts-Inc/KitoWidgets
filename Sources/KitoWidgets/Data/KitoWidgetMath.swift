//
//  KitoWidgetMath.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Progress

/// Progress arithmetic shared by the rings, gauges and counters.
public enum KitoProgress {
    /// `value / goal` clamped to 0...1. A non-positive goal or non-finite input gives 0.
    public static func fraction(_ value: Double, of goal: Double) -> Double {
        ratio(value, of: goal, maxLaps: 1)
    }

    /// `value / goal` clamped to `0...maxLaps`, for rings that keep going past their goal.
    public static func ratio(_ value: Double, of goal: Double, maxLaps: Double = 2) -> Double {
        guard goal > 0, value.isFinite, goal.isFinite, maxLaps > 0 else { return 0 }
        return min(max(value / goal, 0), maxLaps)
    }

    /// Where `value` sits in `range`, clamped to 0...1.
    public static func fraction(_ value: Double, in range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0, value.isFinite else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    /// A whole percentage, rounded down so "100%" only shows once the goal is reached.
    public static func percentText(_ fraction: Double) -> String {
        guard fraction.isFinite else { return "0%" }
        return "\(Int((max(fraction, 0) * 100).rounded(.down)))%"
    }
}

// MARK: - Sparkline

/// Normalises a series for drawing as a sparkline.
public enum KitoSparkline {
    /// Values scaled to 0...1 (min → 0, max → 1). Non-finite values are dropped; a flat or
    /// single-value series sits at 0.5.
    public static func normalized(_ values: [Double]) -> [Double] {
        let finite = values.filter(\.isFinite)
        guard let low = finite.min(), let high = finite.max() else { return [] }
        let span = high - low
        guard span > 0 else { return finite.map { _ in 0.5 } }
        return finite.map { ($0 - low) / span }
    }

    /// Points for `values` across `rect`, oldest on the left, highest at the top.
    public static func points(for values: [Double], in rect: CGRect) -> [CGPoint] {
        let normal = normalized(values)
        guard !normal.isEmpty else { return [] }
        guard normal.count > 1 else { return [CGPoint(x: rect.midX, y: rect.midY)] }
        let step = rect.width / CGFloat(normal.count - 1)
        return normal.enumerated().map { index, value in
            CGPoint(x: rect.minX + CGFloat(index) * step, y: rect.maxY - CGFloat(value) * rect.height)
        }
    }

    /// Minimum, maximum and mean of the finite values, or `nil` when there are none.
    public static func summary(_ values: [Double]) -> (min: Double, max: Double, average: Double)? {
        let finite = values.filter(\.isFinite)
        guard let low = finite.min(), let high = finite.max() else { return nil }
        return (low, high, finite.reduce(0, +) / Double(finite.count))
    }
}

// MARK: - Delta

/// The change between two readings of a stat.
public struct KitoStatDelta: Hashable, Sendable {
    public enum Direction: Hashable, Sendable { case up, down, flat }

    public let current: Double
    public let previous: Double

    public init(current: Double, previous: Double) {
        self.current = current
        self.previous = previous
    }

    /// `current - previous`.
    public var change: Double { current - previous }

    /// The change as a fraction of `previous` (0.12 = +12%), or `nil` when `previous` is 0.
    public var percent: Double? {
        guard previous != 0, previous.isFinite, current.isFinite else { return nil }
        return change / abs(previous)
    }

    /// Up, down, or flat within a hair of zero.
    public var direction: Direction {
        guard change.isFinite, abs(change) > 1e-9 else { return .flat }
        return change > 0 ? .up : .down
    }

    /// "+12%", "−4%" or "0%", falling back to the absolute change when there's no percentage.
    public func text(format: KitoStatFormat = .number(), locale: Locale = .current) -> String {
        let sign = direction == .up ? "+" : direction == .down ? "−" : ""
        if let percent {
            return sign + KitoStatFormat.percent(fractionDigits: abs(percent) < 0.1 && percent != 0 ? 1 : 0)
                .string(for: abs(percent), locale: locale)
        }
        return sign + format.string(for: abs(change), locale: locale)
    }
}

// MARK: - Formatting

/// How a stat's number is written.
public enum KitoStatFormat: Hashable, Sendable {
    /// A grouped number, e.g. "8,432".
    case number(fractionDigits: Int = 0)
    /// A fraction as a percentage: 0.42 → "42%".
    case percent(fractionDigits: Int = 0)
    /// Money in an ISO 4217 currency, e.g. "KES 12,480.00".
    case currency(code: String, fractionDigits: Int = 2)
    /// A short form, e.g. "12.4K".
    case compact
    /// A number followed by a unit, e.g. "8.2 km".
    case unit(String, fractionDigits: Int = 0)

    public func string(for value: Double, locale: Locale = .current) -> String {
        guard value.isFinite else { return "—" }
        switch self {
        case .number(let digits):
            return value.formatted(.number.precision(.fractionLength(max(digits, 0))).locale(locale))
        case .percent(let digits):
            return value.formatted(.percent.precision(.fractionLength(max(digits, 0))).locale(locale))
        case .currency(let code, let digits):
            return value.formatted(.currency(code: code).precision(.fractionLength(max(digits, 0))).locale(locale))
        case .compact:
            return value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(locale))
        case .unit(let unit, let digits):
            return value.formatted(.number.precision(.fractionLength(max(digits, 0))).locale(locale)) + " " + unit
        }
    }
}

// MARK: - Countdown

/// Where a countdown is relative to now.
public enum KitoCountdownPhase: Hashable, Sendable {
    /// More than the final stretch away: show days and a relative date.
    case upcoming
    /// Within the final stretch: show a ticking timer.
    case finalStretch
    /// Between the target and the end date.
    case live
    /// Past the end (or the target, when there's no end).
    case ended
}

/// Countdown arithmetic. All functions take `now` so timelines and tests control the clock.
public enum KitoCountdown {
    /// How long before the target the timer starts ticking. Default 24 hours.
    public static let defaultFinalStretch: TimeInterval = 24 * 60 * 60

    /// The phase at `now`. Exactly at `target` is `.live` when there's a later `end`, else `.ended`;
    /// exactly `finalStretch` before the target is `.finalStretch`.
    public static func phase(at now: Date, target: Date, end: Date? = nil,
                             finalStretch: TimeInterval = defaultFinalStretch) -> KitoCountdownPhase {
        if now < target {
            return target.timeIntervalSince(now) <= finalStretch ? .finalStretch : .upcoming
        }
        if let end, end > target, now < end { return .live }
        return .ended
    }

    /// The dates where the phase changes — use them as timeline entries so the widget switches
    /// layout on time without reloading. Only dates after `now` are returned, in order.
    public static func transitionDates(after now: Date, target: Date, end: Date? = nil,
                                       finalStretch: TimeInterval = defaultFinalStretch) -> [Date] {
        var dates = [target.addingTimeInterval(-max(finalStretch, 0)), target]
        if let end, end > target { dates.append(end) }
        return dates.filter { $0 > now }
    }

    /// Whole days from `now` until `target`'s calendar day (0 on the day itself, never negative).
    public static func daysRemaining(from now: Date, to target: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: target)
        return max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
    }

    /// A compact remaining time: "3d 4h", "4h 12m", "12m" or "<1m". Empty once passed.
    public static func shortText(from now: Date, to target: Date) -> String {
        let seconds = Int(target.timeIntervalSince(now))
        guard seconds > 0 else { return "" }
        let days = seconds / 86_400, hours = (seconds % 86_400) / 3_600, minutes = (seconds % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return minutes > 0 ? "\(minutes)m" : "<1m"
    }
}
