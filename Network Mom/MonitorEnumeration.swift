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
    case OneHour = 3600
    case OneDay = 86400
}

enum MonitorStatus: String, Codable {
    case Green = "Online"
    case Yellow = "Failed last test"
    case Orange = "Failed last two tests"
    case Red = "Offline"
    case Gray = "Never Online"
    
    var improve: MonitorStatus {
        switch self {
        case .Green: return .Green
        case .Yellow: return .Green
        case .Orange: return .Yellow
        case .Red: return .Orange
        case .Gray: return .Orange
        }
    }
    var worsen: MonitorStatus {
        switch self {
        case .Green: return .Yellow
        case .Yellow: return .Orange
        case .Orange: return .Red
        case .Red: return .Red
        case .Gray: return .Gray
        }
    }
    var nsColor: NSColor {
        switch self {
        case .Green: return NSColor.systemGreen
        case .Yellow: return NSColor.systemYellow
        case .Orange: return NSColor.systemOrange
        case .Red: return NSColor.systemRed
        case .Gray: return NSColor.systemGray
        }
    }
    var cgColor: CGColor {
        switch self {
        case .Green: return NSColor.systemGreen.cgColor
        case .Yellow: return NSColor.systemYellow.cgColor
        case .Orange: return NSColor.systemOrange.cgColor
        case .Red: return NSColor.systemRed.cgColor
        case .Gray: return NSColor.systemGray.cgColor
        }
    }
}
