//
//  KitoWidgetsTests.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoWidgets

final class KitoWidgetsTests: XCTestCase {
    func testVersion() {
        XCTAssertFalse(KitoWidgets.version.isEmpty)
    }
}
