//
//  KitoTimeline.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import WidgetKit

/// A timeline entry carrying any value.
public struct KitoWidgetEntry<Value>: TimelineEntry {
    public let date: Date
    public let value: Value
    public let relevance: TimelineEntryRelevance?

    public init(date: Date, value: Value, relevance: TimelineEntryRelevance? = nil) {
        self.date = date
        self.value = value
        self.relevance = relevance
    }
}

/// Helpers for building timelines at regular intervals.
public enum KitoTimeline {
    /// `count` dates `interval` seconds apart, starting at `start`. With `aligned`, the first date
    /// is floored to a multiple of `interval` (e.g. the current quarter hour), so entries land on
    /// round times. Returns `[start]` for a non-positive interval and `[]` for a non-positive count.
    public static func dates(from start: Date, every interval: TimeInterval, count: Int, aligned: Bool = false) -> [Date] {
        guard count > 0 else { return [] }
        guard interval > 0, interval.isFinite else { return [start] }
        let first = aligned ? alignedStart(start, to: interval) : start
        return (0..<count).map { first.addingTimeInterval(Double($0) * interval) }
    }

    /// `date` floored to a multiple of `interval` since the reference date.
    public static func alignedStart(_ date: Date, to interval: TimeInterval) -> Date {
        guard interval > 0, interval.isFinite else { return date }
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / interval).rounded(.down) * interval)
    }

    /// One entry per date from ``dates(from:every:count:aligned:)``.
    public static func entries<Entry>(from start: Date, every interval: TimeInterval, count: Int, aligned: Bool = false,
                                      make: (Date) -> Entry) -> [Entry] {
        dates(from: start, every: interval, count: count, aligned: aligned).map(make)
    }

    /// A timeline of `count` entries that asks for a new timeline one interval after the last entry.
    public static func timeline<Entry: TimelineEntry>(from start: Date, every interval: TimeInterval, count: Int,
                                                      aligned: Bool = false, make: (Date) -> Entry) -> Timeline<Entry> {
        let items = entries(from: start, every: interval, count: count, aligned: aligned, make: make)
        return Timeline(entries: items, policy: .after(reloadDate(after: items.last?.date ?? start, interval: interval)))
    }

    /// When a timeline whose last entry is at `last` should reload.
    public static func reloadDate(after last: Date, interval: TimeInterval) -> Date {
        last.addingTimeInterval(max(interval, 60))
    }
}

/// A ready-made `TimelineProvider` that rebuilds its entry every `interval` seconds.
///
/// ```swift
/// StaticConfiguration(kind: "Steps", provider: KitoIntervalTimelineProvider(
///     placeholder: KitoWidgetEntry(date: .now, value: 8_432.0),
///     interval: 15 * 60
/// ) { date in
///     KitoWidgetEntry(date: date, value: KitoWidgetStore.shared.load(Double.self, forKey: "steps", default: 0))
/// }) { entry in
///     KitoStatWidgetView(title: "Steps", value: entry.value)
/// }
/// ```
public struct KitoIntervalTimelineProvider<Entry: TimelineEntry>: TimelineProvider {
    public let placeholder: Entry
    public let interval: TimeInterval
    public let count: Int
    public let aligned: Bool
    public let makeEntry: @Sendable (Date) -> Entry

    /// - Parameters:
    ///   - placeholder: Shown while the widget loads and in the widget gallery.
    ///   - interval: Seconds between entries. Default 15 minutes.
    ///   - count: Entries per timeline. Default 4.
    ///   - aligned: Floor the first entry to a multiple of `interval`.
    ///   - makeEntry: Builds the entry for a date, typically by reading ``KitoWidgetStore``.
    public init(placeholder: Entry, interval: TimeInterval = 15 * 60, count: Int = 4, aligned: Bool = false,
                makeEntry: @escaping @Sendable (Date) -> Entry) {
        self.placeholder = placeholder
        self.interval = interval
        self.count = count
        self.aligned = aligned
        self.makeEntry = makeEntry
    }

    public func placeholder(in context: Context) -> Entry { placeholder }

    public func getSnapshot(in context: Context, completion: @escaping @Sendable (Entry) -> Void) {
        completion(context.isPreview ? placeholder : makeEntry(Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        completion(KitoTimeline.timeline(from: Date(), every: interval, count: count, aligned: aligned, make: makeEntry))
    }
}
