//
//  DLog.swift
//  DLog
//
//  Created by Darrell Root on 11/16/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation

public enum DLogCategories: String, CaseIterable {
    case dns
    case dataIntegrity
    case icmp
    case license
    case monitor
    case mail
    case userInterface
    case other
}

public class DLog {
    public static var logdata:
        [DLogCategories:RRDBuffer<String>] = [
            .dns:RRDBuffer<String>(count: 1000),
            .dataIntegrity:RRDBuffer<String>(count: 1000),
            .icmp:RRDBuffer<String>(count: 1000),
            .license:RRDBuffer<String>(count: 1000),
            .monitor:RRDBuffer<String>(count: 1000),
            .mail:RRDBuffer<String>(count: 1000),
            .userInterface:RRDBuffer<String>(count: 1000),
            .other:RRDBuffer<String>(count: 1000),
            ]
    //public static let defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    public static let defaultDateFormat = "yyyy-MM-dd HH:mm:ss"
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
        debugPrint(message)
    }
    static public func log(_ category: DLogCategories,_ msg: String) {
        let message = DLog.formatDate() + " " + msg + "\n"
        DLog.logdata[category]?.insert(message)
        if category != .icmp {
            DLog.doPrint(message)
        }
    }
}
