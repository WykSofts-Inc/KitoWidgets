//
//  KitoWidgetsTests.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
import WidgetKit
@testable import KitoWidgets

// MARK: - Store

final class KitoWidgetStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "KitoWidgetsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testRoundTripsCodableValues() throws {
        let store = KitoWidgetStore(defaults: defaults)
        let tasks = [KitoWidgetTask(id: "a", title: "Milk", detail: "Groceries", due: Date(timeIntervalSince1970: 1_000)),
                     KitoWidgetTask(id: "b", title: "Call mum", isDone: true)]
        try store.save(tasks, forKey: "tasks")
        XCTAssertEqual(store.load([KitoWidgetTask].self, forKey: "tasks"), tasks)

        let counter = KitoWidgetCounter(count: 3, goal: 8, unit: "glasses", day: Date(timeIntervalSince1970: 0))
        try store.save(counter, forKey: "water")
        XCTAssertEqual(store.load(KitoWidgetCounter.self, forKey: "water"), counter)
    }

    func testMissingAndUndecodableValuesFallBack() throws {
        let store = KitoWidgetStore(defaults: defaults)
        XCTAssertNil(store.load(Int.self, forKey: "missing"))
        XCTAssertEqual(store.load(Int.self, forKey: "missing", default: 7), 7)
        defaults.set(Data("not json".utf8), forKey: "broken")
        XCTAssertNil(store.load([KitoWidgetTask].self, forKey: "broken"))
        try store.save("text", forKey: "wrongType")
        XCTAssertNil(store.load(Int.self, forKey: "wrongType"))
    }

    func testUpdateMutatesAndSaves() throws {
        let store = KitoWidgetStore(defaults: defaults)
        let first = try store.update(Int.self, forKey: "n", default: 10) { $0 += 1 }
        let second = try store.update(Int.self, forKey: "n", default: 10) { $0 += 1 }
        XCTAssertEqual(first, 11)
        XCTAssertEqual(second, 12)
        XCTAssertEqual(store.load(Int.self, forKey: "n"), 12)
    }

    func testRemoveAndPendingDeepLink() throws {
        let store = KitoWidgetStore(defaults: defaults)
        let url = try XCTUnwrap(URL(string: "kito://today"))
        try store.save(url, forKey: KitoWidgetStore.pendingDeepLinkKey)
        XCTAssertEqual(store.consumePendingDeepLink(), url)
        XCTAssertNil(store.consumePendingDeepLink())
        try store.save(1, forKey: "x")
        store.remove(forKey: "x")
        XCTAssertNil(store.load(Int.self, forKey: "x"))
    }

    func testWritesPostChangeNotification() throws {
        let store = KitoWidgetStore(defaults: defaults)
        let posted = expectation(forNotification: KitoWidgetStore.didChangeNotification, object: nil) { note in
            (note.object as? String) == "k"
        }
        try store.save(true, forKey: "k")
        wait(for: [posted], timeout: 1)
    }

    func testMissingAppGroupFallsBackToStandardDefaults() {
        let store = KitoWidgetStore(appGroup: nil)
        XCTAssertNil(store.appGroup)
        XCTAssertTrue(store.defaults === UserDefaults.standard)
    }
}

// MARK: - Timeline

final class KitoTimelineTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 10_000)

    func testDatesAreEvenlySpaced() {
        let dates = KitoTimeline.dates(from: start, every: 900, count: 4)
        XCTAssertEqual(dates, [0, 900, 1_800, 2_700].map { start.addingTimeInterval($0) })
    }

    func testAlignedDatesStartOnABoundary() {
        let dates = KitoTimeline.dates(from: start, every: 900, count: 2, aligned: true)
        // 10_000 floors to 9_900, the nearest multiple of 900 below it.
        XCTAssertEqual(dates.first, Date(timeIntervalSinceReferenceDate: 9_900))
        XCTAssertEqual(dates.last, Date(timeIntervalSinceReferenceDate: 10_800))
        XCTAssertEqual(KitoTimeline.alignedStart(start, to: 0), start)
    }

    func testDegenerateInputs() {
        XCTAssertEqual(KitoTimeline.dates(from: start, every: 900, count: 0), [])
        XCTAssertEqual(KitoTimeline.dates(from: start, every: 0, count: 5), [start])
        XCTAssertEqual(KitoTimeline.dates(from: start, every: -60, count: 5), [start])
        XCTAssertEqual(KitoTimeline.dates(from: start, every: .infinity, count: 5), [start])
    }

    func testEntriesAndTimelineReloadPolicy() {
        let entries = KitoTimeline.entries(from: start, every: 60, count: 3) { KitoWidgetEntry(date: $0, value: $0.timeIntervalSince(self.start)) }
        XCTAssertEqual(entries.map(\.value), [0, 60, 120])

        let timeline = KitoTimeline.timeline(from: start, every: 600, count: 2) { KitoWidgetEntry(date: $0, value: 1) }
        XCTAssertEqual(timeline.entries.count, 2)
        XCTAssertEqual(timeline.policy, .after(start.addingTimeInterval(1_200)))
        // Never asks for a reload sooner than a minute after the last entry.
        XCTAssertEqual(KitoTimeline.reloadDate(after: start, interval: 5), start.addingTimeInterval(60))
    }
}

// MARK: - Progress, sparkline, delta, format

final class KitoWidgetMathTests: XCTestCase {
    func testProgressClamping() {
        XCTAssertEqual(KitoProgress.fraction(50, of: 100), 0.5)
        XCTAssertEqual(KitoProgress.fraction(150, of: 100), 1)
        XCTAssertEqual(KitoProgress.fraction(-5, of: 100), 0)
        XCTAssertEqual(KitoProgress.fraction(5, of: 0), 0)
        XCTAssertEqual(KitoProgress.fraction(.nan, of: 10), 0)
        XCTAssertEqual(KitoProgress.ratio(250, of: 100), 2)
        XCTAssertEqual(KitoProgress.ratio(150, of: 100), 1.5)
        XCTAssertEqual(KitoProgress.fraction(75, in: 50...150), 0.25)
        XCTAssertEqual(KitoProgress.fraction(10, in: 5...5), 0)
    }

    func testPercentTextRoundsDown() {
        XCTAssertEqual(KitoProgress.percentText(0.999), "99%")
        XCTAssertEqual(KitoProgress.percentText(1), "100%")
        XCTAssertEqual(KitoProgress.percentText(0.425), "42%")
        XCTAssertEqual(KitoProgress.percentText(-1), "0%")
        XCTAssertEqual(KitoProgress.percentText(.infinity), "0%")
    }

    func testSparklineNormalisation() {
        XCTAssertEqual(KitoSparkline.normalized([2, 4, 6]), [0, 0.5, 1])
        XCTAssertEqual(KitoSparkline.normalized([3, 3, 3]), [0.5, 0.5, 0.5])
        XCTAssertEqual(KitoSparkline.normalized([7]), [0.5])
        XCTAssertEqual(KitoSparkline.normalized([]), [])
        XCTAssertEqual(KitoSparkline.normalized([1, .nan, 3, .infinity]), [0, 1])
    }

    func testSparklinePoints() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let points = KitoSparkline.points(for: [0, 10, 5], in: rect)
        XCTAssertEqual(points, [CGPoint(x: 0, y: 50), CGPoint(x: 50, y: 0), CGPoint(x: 100, y: 25)])
        XCTAssertEqual(KitoSparkline.points(for: [4], in: rect), [CGPoint(x: 50, y: 25)])
        let summary = KitoSparkline.summary([1, 2, 6])
        XCTAssertEqual(summary?.min, 1)
        XCTAssertEqual(summary?.max, 6)
        XCTAssertEqual(summary?.average, 3)
        XCTAssertNil(KitoSparkline.summary([]))
    }

    func testDelta() {
        let up = KitoStatDelta(current: 112, previous: 100)
        XCTAssertEqual(up.direction, .up)
        XCTAssertEqual(up.change, 12)
        XCTAssertEqual(up.percent ?? 0, 0.12, accuracy: 1e-9)
        XCTAssertEqual(up.text(locale: Locale(identifier: "en_US")), "+12%")

        let down = KitoStatDelta(current: 95.8, previous: 100)
        XCTAssertEqual(down.direction, .down)
        XCTAssertEqual(down.text(locale: Locale(identifier: "en_US")), "−4.2%")

        XCTAssertEqual(KitoStatDelta(current: 5, previous: 5).direction, .flat)
        let fromZero = KitoStatDelta(current: 30, previous: 0)
        XCTAssertNil(fromZero.percent)
        XCTAssertEqual(fromZero.text(locale: Locale(identifier: "en_US")), "+30")
    }

    func testStatFormat() {
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(KitoStatFormat.number().string(for: 8_432, locale: us), "8,432")
        XCTAssertEqual(KitoStatFormat.number(fractionDigits: 1).string(for: 3.14159, locale: us), "3.1")
        XCTAssertEqual(KitoStatFormat.percent().string(for: 0.42, locale: us), "42%")
        XCTAssertEqual(KitoStatFormat.currency(code: "USD").string(for: 1_234.5, locale: us), "$1,234.50")
        XCTAssertEqual(KitoStatFormat.compact.string(for: 12_400, locale: us), "12.4K")
        XCTAssertEqual(KitoStatFormat.unit("km", fractionDigits: 1).string(for: 8.25, locale: us), "8.2 km")
        XCTAssertEqual(KitoStatFormat.number().string(for: .nan, locale: us), "—")
    }
}

// MARK: - Countdown

final class KitoCountdownTests: XCTestCase {
    private let target = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let day: TimeInterval = 86_400

    func testPhaseBoundaries() {
        XCTAssertEqual(KitoCountdown.phase(at: target.addingTimeInterval(-day - 1), target: target), .upcoming)
        XCTAssertEqual(KitoCountdown.phase(at: target.addingTimeInterval(-day), target: target), .finalStretch)
        XCTAssertEqual(KitoCountdown.phase(at: target.addingTimeInterval(-1), target: target), .finalStretch)
        XCTAssertEqual(KitoCountdown.phase(at: target, target: target), .ended)
        let end = target.addingTimeInterval(3_600)
        XCTAssertEqual(KitoCountdown.phase(at: target, target: target, end: end), .live)
        XCTAssertEqual(KitoCountdown.phase(at: end.addingTimeInterval(-1), target: target, end: end), .live)
        XCTAssertEqual(KitoCountdown.phase(at: end, target: target, end: end), .ended)
        // An end before the target is ignored.
        XCTAssertEqual(KitoCountdown.phase(at: target, target: target, end: target.addingTimeInterval(-10)), .ended)
        XCTAssertEqual(KitoCountdown.phase(at: target.addingTimeInterval(-120), target: target, finalStretch: 60), .upcoming)
    }

    func testTransitionDates() {
        let end = target.addingTimeInterval(3_600)
        let early = target.addingTimeInterval(-2 * day)
        XCTAssertEqual(KitoCountdown.transitionDates(after: early, target: target, end: end),
                       [target.addingTimeInterval(-day), target, end])
        XCTAssertEqual(KitoCountdown.transitionDates(after: target, target: target, end: end), [end])
        XCTAssertEqual(KitoCountdown.transitionDates(after: end, target: target, end: end), [])
    }

    func testDaysRemainingCountsCalendarDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let late = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 23, hour: 23)))
        let nextMorning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 1)))
        XCTAssertEqual(KitoCountdown.daysRemaining(from: late, to: nextMorning, calendar: calendar), 1)
        XCTAssertEqual(KitoCountdown.daysRemaining(from: late, to: late, calendar: calendar), 0)
        XCTAssertEqual(KitoCountdown.daysRemaining(from: nextMorning, to: late, calendar: calendar), 0)
    }

    func testShortText() {
        XCTAssertEqual(KitoCountdown.shortText(from: target.addingTimeInterval(-(3 * day + 4 * 3_600 + 5)), to: target), "3d 4h")
        XCTAssertEqual(KitoCountdown.shortText(from: target.addingTimeInterval(-(4 * 3_600 + 12 * 60)), to: target), "4h 12m")
        XCTAssertEqual(KitoCountdown.shortText(from: target.addingTimeInterval(-12 * 60), to: target), "12m")
        XCTAssertEqual(KitoCountdown.shortText(from: target.addingTimeInterval(-30), to: target), "<1m")
        XCTAssertEqual(KitoCountdown.shortText(from: target, to: target), "")
    }
}

// MARK: - Tasks and counters

final class KitoWidgetModelTests: XCTestCase {
    func testToggleTask() {
        var tasks = [KitoWidgetTask(id: "a", title: "A"), KitoWidgetTask(id: "b", title: "B")]
        XCTAssertEqual(tasks.toggle(id: "b"), true)
        XCTAssertEqual(tasks.completedCount, 1)
        XCTAssertEqual(tasks.completionFraction, 0.5)
        XCTAssertEqual(tasks.openFirst.map(\.id), ["a", "b"])
        XCTAssertEqual(tasks.toggle(id: "b"), false)
        XCTAssertEqual(tasks.completedCount, 0)
        let before = tasks
        XCTAssertNil(tasks.toggle(id: "zzz"))
        XCTAssertEqual(tasks, before)
        XCTAssertEqual([KitoWidgetTask]().completionFraction, 0)
    }

    func testOpenFirstKeepsOrder() {
        let tasks = [KitoWidgetTask(id: "1", title: "1", isDone: true), KitoWidgetTask(id: "2", title: "2"),
                     KitoWidgetTask(id: "3", title: "3", isDone: true), KitoWidgetTask(id: "4", title: "4")]
        XCTAssertEqual(tasks.openFirst.map(\.id), ["2", "4", "1", "3"])
    }

    func testCounterIncrementsAndResetsDaily() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let monday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 9)))
        let tuesday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 8)))

        var counter = KitoWidgetCounter(count: 0, goal: 4, day: calendar.startOfDay(for: monday))
        counter.increment(at: monday, calendar: calendar)
        counter.increment(by: 2, at: monday, calendar: calendar)
        XCTAssertEqual(counter.count, 3)
        XCTAssertEqual(counter.progress, 0.75)
        XCTAssertFalse(counter.isComplete)
        counter.increment(by: -10, at: monday, calendar: calendar)
        XCTAssertEqual(counter.count, 0)

        counter.increment(by: 5, at: monday, calendar: calendar)
        XCTAssertTrue(counter.isComplete)
        XCTAssertEqual(counter.progress, 1)
        XCTAssertEqual(counter.current(at: tuesday, calendar: calendar).count, 0)
        counter.increment(at: tuesday, calendar: calendar)
        XCTAssertEqual(counter.count, 1)
        XCTAssertEqual(counter.day, calendar.startOfDay(for: tuesday))
    }

    func testCounterSanitisesInit() {
        let counter = KitoWidgetCounter(count: -3, goal: 0)
        XCTAssertEqual(counter.count, 0)
        XCTAssertEqual(counter.goal, 1)
    }

    func testRingProgress() {
        let ring = KitoRing(title: "Move", value: 900, goal: 600, color: .pink)
        XCTAssertEqual(ring.id, "Move")
        XCTAssertEqual(ring.progress, 1)
        XCTAssertEqual(ring.laps, 1.5)
    }

    func testShortcutItemsFallBackToSamples() throws {
        let suite = "KitoWidgetsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = KitoWidgetStore(defaults: defaults)
        XCTAssertEqual(KitoShortcutItem.all(in: store), KitoShortcutItem.samples)
        XCTAssertEqual(KitoShortcutItem.samples.count, 4)
        let custom = [KitoShortcutItem(id: "x", title: "X", symbol: "star", url: try XCTUnwrap(URL(string: "app://x")))]
        try store.save(custom, forKey: KitoShortcutItem.storeKey)
        XCTAssertEqual(KitoShortcutItem.all(in: store), custom)
    }
}

// MARK: - Metrics

final class KitoWidgetMetricsTests: XCTestCase {
    func testFamilySizes() {
        XCTAssertEqual(KitoWidgetMetrics.size(for: .systemSmall), CGSize(width: 158, height: 158))
        XCTAssertEqual(KitoWidgetMetrics.size(for: .systemMedium), CGSize(width: 338, height: 158))
        XCTAssertEqual(KitoWidgetMetrics.size(for: .systemLarge), CGSize(width: 338, height: 354))
        XCTAssertEqual(KitoWidgetMetrics.size(for: .accessoryCircular), CGSize(width: 72, height: 72))
        XCTAssertEqual(KitoWidgetMetrics.cornerRadius(for: .systemSmall), 22)
        XCTAssertEqual(KitoWidgetMetrics.cornerRadius(for: .accessoryRectangular), 0)
        XCTAssertEqual(KitoWidgetMetrics.contentMargin(for: .systemMedium), 16)
        XCTAssertEqual(KitoWidgetMetrics.contentMargin(for: .accessoryInline), 0)
        XCTAssertTrue(WidgetFamily.accessoryInline.kitoIsAccessory)
        XCTAssertFalse(WidgetFamily.systemLarge.kitoIsAccessory)
    }

    func testEveryViewDeclaresItsFamilies() {
        XCTAssertEqual(KitoStatWidgetView.supportedFamilies.count, 6)
        XCTAssertEqual(KitoProgressRingWidgetView.supportedFamilies.count, 6)
        XCTAssertEqual(KitoCountdownWidgetView.supportedFamilies.count, 6)
        XCTAssertEqual(KitoCounterWidgetView.supportedFamilies.count, 6)
        XCTAssertTrue(KitoPhotoWidgetView.supportedFamilies.allSatisfy { !$0.kitoIsAccessory })
        XCTAssertEqual(KitoWidgetGradient.presets.count, 10)
    }
}
