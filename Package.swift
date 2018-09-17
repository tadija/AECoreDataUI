// swift-tools-version:4.2

/**
 *  https://github.com/tadija/AECoreDataUI
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "AECoreDataUI",
    targets: [
        .target(
            name: "AECoreDataUI"
        ),
        .testTarget(
            name: "AECoreDataUITests",
            dependencies: ["AECoreDataUI"]
        )
    ]
)
