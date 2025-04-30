//
//  Item.swift
//  IntervalTimerClock
//
//  Created by Allan Ientz on 4/30/25.
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
