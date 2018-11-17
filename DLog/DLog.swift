//
//  DLog.swift
//  DLog
//
//  Created by Darrell Root on 11/16/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation

public enum DLogCategories: String, CaseIterable {
    case monitor
    case mail
    case userInterface
}

public class DLog {
    public static var logdata:
        [DLogCategories:RRDBuffer<String>] = [
            .monitor:RRDBuffer<String>(count: 1000),
            .mail:RRDBuffer<String>(count: 1000),
            .userInterface:RRDBuffer<String>(count: 1000),
            ]
    public static let defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    static fileprivate var dateFormatter: DateFormatter = DLog.getDateFormatter()

    static func getDateFormatter(format: String? = nil, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        
        if let dateFormat = format {
            formatter.dateFormat = dateFormat
        } else {
            formatter.dateFormat = defaultDateFormat
        }
        
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        
        return formatter
    }
    static func formatDate(_ date: Date = Date()) -> String {
        return dateFormatter.string(from: date)
    }

    static func doPrint(_ message: String) {
        print(message)
    }
    static public func log(_ category: DLogCategories, msg: String) {
        let message = DLog.formatDate() + " " + msg
        DLog.logdata[category]!.insert(message)
        DLog.doPrint(message)
    }
}
