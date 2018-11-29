//
//  Notification.swift
//  Network Mom
//
//  Created by Darrell Root on 11/28/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation

class EmailNotification: CustomStringConvertible {
    
    let map: String
    let hostname: String?
    let ip: String
    let type: MonitorEnumeration
    let newStatus: MonitorStatus
    let comment: String?
    let date: Date
    let dateFormatter = DateFormatter()
    
    var description: String {
        let dateString = dateFormatter.string(from: date)
        let hostname = self.hostname ?? ""
        let comment = self.comment ?? ""
        return("\(dateString) \(map) \(hostname) \(ip) \(type.rawValue) \(newStatus.rawValue) \(comment)")
    }

    init(map: String, hostname: String?, ip: String, comment: String?, type: MonitorEnumeration, newStatus: MonitorStatus) {
        self.map = map
        self.hostname = hostname
        self.ip = ip
        self.type = type
        self.newStatus = newStatus
        self.comment = comment
        self.date = Date()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
    }
    
}
