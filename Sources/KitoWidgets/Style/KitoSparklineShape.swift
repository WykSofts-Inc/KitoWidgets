//
//  KitoSparklineShape.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import WidgetKit

/// A smooth line through a series, scaled to fill its frame. With `closed`, the area under the
/// line, for a gradient fill.
public struct KitoSparklineShape: Shape {
    public var values: [Double]
    public var closed: Bool

    public init(values: [Double], closed: Bool = false) {
        self.values = values
        self.closed = closed
    }

    public func path(in rect: CGRect) -> Path {
        let points = KitoSparkline.points(for: values, in: rect)
        var path = Path()
        guard let first = points.first else { return path }
        guard points.count > 1 else {
            path.move(to: CGPoint(x: rect.minX, y: first.y))
            path.addLine(to: CGPoint(x: rect.maxX, y: first.y))
            return path
        }
        path.move(to: first)
        // Catmull-Rom through the points, as cubic Béziers, with a gentle tension.
        for index in 0..<(points.count - 1) {
            let p0 = points[max(index - 1, 0)], p1 = points[index]
            let p2 = points[index + 1], p3 = points[min(index + 2, points.count - 1)]
            let tension: CGFloat = 1 / 6
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        if closed, let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
            path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// A sparkline with a gradient fill and a dot on the latest value.
struct KitoSparklineView: View {
    let values: [Double]
    let tint: Color
    var lineWidth: CGFloat = 2.5
    var showsFill = true
    var showsDot = true

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size).insetBy(dx: lineWidth, dy: lineWidth)
            ZStack {
                if showsFill {
                    KitoSparklineShape(values: values, closed: true)
                        .fill(LinearGradient(colors: [tint.opacity(0.45), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
                KitoSparklineShape(values: values)
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .widgetAccentable()
                if showsDot, let last = KitoSparkline.points(for: values, in: rect).last {
                    Circle()
                        .fill(tint)
                        .frame(width: lineWidth * 3, height: lineWidth * 3)
                        .overlay(Circle().stroke(.white, lineWidth: lineWidth * 0.8))
                        .position(last)
                        .widgetAccentable()
                }
            }
        }
        .accessibilityHidden(true)
    }
}
