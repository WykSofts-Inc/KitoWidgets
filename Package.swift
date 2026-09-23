// swift-tools-version: 5.9
//
//  Package.swift
//  KitoWidgets
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoWidgets",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoWidgets", targets: ["KitoWidgets"])],
    targets: [
        .target(name: "KitoWidgets"),
        .testTarget(name: "KitoWidgetsTests", dependencies: ["KitoWidgets"]),
    ]
)
