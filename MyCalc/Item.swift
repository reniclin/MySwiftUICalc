//
//  Item.swift
//  MyCalc
//
//  Created by Renic Lin on 2025/3/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
