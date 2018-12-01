//
//  MonitorEnumeration.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/14/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation
import AppKit

enum MonitorEnumeration: String, Codable {
    case MonitorIPv4
    case MonitorIPv6
}

enum MonitorDataType: Int, CaseIterable, Codable {
    case FiveMinute = 300
    case ThirtyMinute = 1800
    case TwoHour = 7200
    case OneDay = 86400
}

enum MonitorStatus: String, Codable {
    case Green = "Online"
    case Yellow = "Failed last test"
    case Orange = "Failed last two tests"
    case Red = "Offline"
    case Blue = "Never Online"
    
    var improve: MonitorStatus {
        switch self {
        case .Green: return .Green
        case .Yellow: return .Green
        case .Orange: return .Yellow
        case .Red: return .Orange
        case .Blue: return .Orange
        }
    }
    var worsen: MonitorStatus {
        switch self {
        case .Green: return .Yellow
        case .Yellow: return .Orange
        case .Orange: return .Red
        case .Red: return .Red
        case .Blue: return .Blue
        }
    }
    var nsColor: NSColor {
        switch self {
        case .Green: return NSColor.systemGreen
        case .Yellow: return NSColor.systemYellow
        case .Orange: return NSColor.systemOrange
        case .Red: return NSColor.systemRed
        case .Blue: return NSColor.systemBlue
        }
    }
    var cgColor: CGColor {
        switch self {
        case .Green: return NSColor.systemGreen.cgColor
        case .Yellow: return NSColor.systemYellow.cgColor
        case .Orange: return NSColor.systemOrange.cgColor
        case .Red: return NSColor.systemRed.cgColor
        case .Blue: return NSColor.systemBlue.cgColor
        }
    }
}
