//
//  MonitorIPv6.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/12/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation
import Network
import DLog

class MonitorIPv6: Monitor {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var coreMonitorIPv6: CoreMonitorIPv6?

    var ipv6: IPv6Address
    
    //var ipv6string: String
    var sockaddrin: sockaddr_in6
    var lastPingID: UInt16 = 0      //last ping id sent
    var lastPingSequence: UInt16 = 0     //last ping id sent
    let type: MonitorEnumeration = .MonitorIPv6
    //let ipv4: UInt32
    var lastIdReceived: UInt16 = 0
    var lastSequenceReceived: UInt16 = 0
    private var pingSentDate: Date?
    var status: MonitorStatus = .Blue {
        didSet {
            viewDelegate?.needsDisplay = true
        }
    }
    var lastAlertStatus: MonitorStatus = .Blue
    var hostname: String?
    var comment: String? {
        didSet {
            viewDelegate?.updateFrame()
        }
    }
    var availability: RRDGauge
    var latency: RRDGauge
    var viewFrame: NSRect?

    weak var viewDelegate: DragMonitorView?
    weak var mapDelegate: MapWindowController?
    
    init?(coreData: CoreMonitorIPv6) {
        self.coreMonitorIPv6 = coreData
        guard let ipv6String = coreData.ipv6String else { return nil }
        guard let ipv6 = IPv6Address(ipv6String) else { return nil }
        self.ipv6 = ipv6
        if let sockaddrin = sockaddr_in6(ipv6: ipv6, port: 0) {
            self.sockaddrin = sockaddrin
        } else {
            return nil
        }
        self.hostname = coreData.hostname
        self.comment = coreData.comment
        self.viewFrame = NSRect(x: CGFloat(coreData.frameX), y: CGFloat(coreData.frameY), width: CGFloat(coreData.frameWidth), height: CGFloat(coreData.frameHeight))
        do {
            let fiveMinCoreData = coreData.availabilityFiveMinuteData ?? []
            let fiveMinCoreTime = coreData.availabilityFiveMinuteTimestamp ?? []
            let thirtyMinCoreData = coreData.availabilityThirtyMinuteData ?? []
            let thirtyMinCoreTime = coreData.availabilityThirtyMinuteTimestamp ?? []
            let twoHourCoreData = coreData.availabilityTwoHourData ?? []
            let twoHourCoreTime = coreData.availabilityTwoHourTimestamp ?? []
            let dayCoreData = coreData.availabilityDayData ?? []
            let dayCoreTime = coreData.availabilityDayTimestamp ?? []
            availability = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, thirtyMinData: thirtyMinCoreData, thirtyMinTime: thirtyMinCoreTime, twoHourData: twoHourCoreData, twoHourTime: twoHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        }
        do {
            let fiveMinCoreData = coreData.latencyFiveMinuteData ?? []
            let fiveMinCoreTime = coreData.latencyFiveMinuteTimestamp ?? []
            let thirtyMinCoreData = coreData.latencyThirtyMinuteData ?? []
            let thirtyMinCoreTime = coreData.latencyThirtyMinuteTimestamp ?? []
            let twoHourCoreData = coreData.latencyTwoHourData ?? []
            let twoHourCoreTime = coreData.latencyTwoHourTimestamp ?? []
            let dayCoreData = coreData.latencyDayData ?? []
            let dayCoreTime = coreData.latencyDayTimestamp ?? []
            latency = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, thirtyMinData: thirtyMinCoreData, thirtyMinTime: thirtyMinCoreTime, twoHourData: twoHourCoreData, twoHourTime: twoHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        }
    }

    func writeCoreData() {
        guard let coreData = coreMonitorIPv6 else {
            DLog.log(.dataIntegrity,"Warning: no coreMonitorIPv6 core data structure in MonitorIPv6 \(ipv6.debugDescription)")
            return
        }
        coreData.frameHeight = Float(viewFrame?.height ?? 200.0)
        coreData.frameWidth = Float(viewFrame?.width ?? 200.0)
        coreData.frameX = Float(viewFrame?.minX ?? 40.0)
        coreData.frameY = Float(viewFrame?.minY ?? 40.0)
        coreData.comment = self.comment
        coreData.hostname = self.hostname
        coreData.ipv6String = self.ipv6.debugDescription
        
        for dataType in MonitorDataType.allCases {
            let data = availability.getData(dataType: dataType)
            var timestamps: [Int] = []
            var values: [Double] = []
            for dataPoint in data {
                if let value = dataPoint.value {
                    timestamps.append(dataPoint.timestamp)
                    values.append(value)
                }
            }
            switch dataType {
            case .FiveMinute:
                coreData.availabilityFiveMinuteTimestamp = timestamps
                coreData.availabilityFiveMinuteData = values
            case .ThirtyMinute:
                coreData.availabilityThirtyMinuteTimestamp = timestamps
                coreData.availabilityThirtyMinuteData = values
            case .TwoHour:
                coreData.availabilityTwoHourTimestamp = timestamps
                coreData.availabilityTwoHourData = values
            case .OneDay:
                coreData.availabilityDayTimestamp = timestamps
                coreData.availabilityDayData = values
            }
            DLog.log(.dataIntegrity, "Monitor IPv6 \(ipv6.debugDescription) availability wrote dataType \(dataType) \(values.count) entries")
        }
        
        for dataType in MonitorDataType.allCases {
            let data = latency.getData(dataType: dataType)
            var timestamps: [Int] = []
            var values: [Double] = []
            for dataPoint in data {
                if let value = dataPoint.value {
                    timestamps.append(dataPoint.timestamp)
                    values.append(value)
                }
            }
            switch dataType {
            case .FiveMinute:
                coreData.latencyFiveMinuteTimestamp = timestamps
                coreData.latencyFiveMinuteData = values
            case .ThirtyMinute:
                coreData.latencyThirtyMinuteTimestamp = timestamps
                coreData.latencyThirtyMinuteData = values
            case .TwoHour:
                coreData.latencyTwoHourTimestamp = timestamps
                coreData.latencyTwoHourData = values
            case .OneDay:
                coreData.latencyDayTimestamp = timestamps
                coreData.latencyDayData = values
            }
            DLog.log(.dataIntegrity, "Monitor IPv6 \(ipv6.debugDescription) latency wrote dataType \(dataType) \(values.count) entries")
        }
    }

    init?(ipv6: IPv6Address, hostname: String?, comment: String?) {
        self.hostname = hostname
        self.comment = comment
        self.ipv6 = ipv6
        guard let tmpsockaddrin = sockaddr_in6(ipv6: ipv6, port: 0) else { return nil }
        self.sockaddrin = tmpsockaddrin
        availability = RRDGauge()
        latency = RRDGauge()
        coreMonitorIPv6 = CoreMonitorIPv6(context: appDelegate.managedContext)
        self.writeCoreData()
    }
    var label: String {
        var label = ""
        if let hostname = hostname {
            label += hostname
        }
        label = label + "\n" + ipv6.debugDescription
        if let comment = comment {
            label = label + "\n" + comment
        }
        return label
    }

    deinit {
        DLog.log(.dataIntegrity,"deallocating ipv6 monitor \(ipv6.debugDescription)")
        if let coreMonitorIPv6 = self.coreMonitorIPv6 {
            DLog.log(.dataIntegrity,"deleting ipv6 nsmanaged object self.ipv6.debugDescription")
            coreMonitorIPv6.managedObjectContext?.delete(coreMonitorIPv6)
        }
    }

    func sendPing(pingSocket: CFSocket?) {
        sendPing(pingSocket: pingSocket, id: 400)
    }

    func sendPing(pingSocket: CFSocket?, id: Int) {
        //make sure we send an ipv6 icmp socket, not an ipv4 icmp socket
        let pingID = UInt16(id)
        if lastPingID != lastIdReceived || lastPingSequence != lastSequenceReceived {
            let oldstatus = status
            status = status.worsen
            if oldstatus != status {
                DLog.log(.monitor,"target \(ipv6.debugDescription) status worsened to \(status)")
            }
            if status != .Blue {
                // we don't count availability for devices which were never online
                availability.update(newData: 0.0)
            }
            if oldstatus == .Orange && status == .Red {
                if lastAlertStatus == .Green {
                    if let map = mapDelegate {
                        DLog.log(.mail, "Adding email alert for \(ipv6.debugDescription)")
                        let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv6.debugDescription, comment: comment, type: self.type, newStatus: .Red)
                        for emailAddress in map.emailAlerts {
                            appDelegate.pendNotification(emailAddress: emailAddress, notification: notification)
                        }
                    }
                }
                lastAlertStatus = .Red
            }
        }
        if lastPingID == UInt16.max { lastPingID = 0 }
        if lastPingSequence == UInt16.max { lastPingSequence = 0 }
        lastPingID = pingID
        lastPingSequence += 1
        var myPacket = IcmpV6EchoRequest(id: lastPingID, sequence: lastPingSequence)
        let myPacketCFData = NSData(bytes: &myPacket, length: MemoryLayout<IcmpEchoRequest>.size) as CFData
        guard pingSocket != nil else { DLog.log(.monitor,"sendPing failed: socket nil"); return}
        let mySockCFData = NSData(bytes: &sockaddrin,length: MemoryLayout<sockaddr_in6>.size) as CFData
        let socketError = CFSocketSendData(pingSocket, mySockCFData as CFData, myPacketCFData, 1)
        pingSentDate = Date()
        DLog.log(.monitor,"sent ping to \(ipv6.debugDescription)")
    }
    public func latencyStatus() -> MonitorStatus? {
        if let currentLatency = latency.lastFiveMinute?.value, let yesterdayLatency = latency.lastThirtyMinute?.value {   // change to lastDay when we go production
            if currentLatency > yesterdayLatency * Defaults.latencyPercentThresholdRed + Defaults.latencyStaticThreshold {
                return MonitorStatus.Red
            }
            if currentLatency > yesterdayLatency * Defaults.latencyPercentThresholdOrange + Defaults.latencyStaticThreshold {
                return MonitorStatus.Orange
            }
            if currentLatency > yesterdayLatency * Defaults.latencyPercentThresholdYellow + Defaults.latencyStaticThreshold {
                return MonitorStatus.Yellow
            }
            return MonitorStatus.Green
        }
        return MonitorStatus.Blue
    }
    func receivedPing(receivedip: IPv6Address, sequence: UInt16, id: UInt16) {
        DLog.log(.monitor,"\(self.ipv6.debugDescription) received ping")
        guard receivedip == self.ipv6 && sequence == lastPingSequence && id == lastPingID else {
            DLog.log(.monitor,"icmp return mismatch sent \(ipv6.debugDescription) seq \(lastPingSequence) id \(lastPingID)")
            DLog.log(.monitor,"icmp return mismatch received \(receivedip) seq \(sequence) id \(id)")
            return
        }
        if let pingSentDate = pingSentDate {
            let interval = Date().timeIntervalSince(pingSentDate) * 1000
            latency.update(newData: interval)
            DLog.log(.monitor,"ping interval \(interval)msec")
        }
        lastSequenceReceived = sequence
        lastIdReceived = id
        availability.update(newData: 1.0)
        if let mapWindowController = mapDelegate {
            mapWindowController.availability.update(newData: 1.0)
        }
        let oldstatus = status
        status = status.improve
        if oldstatus != status {
            DLog.log(.monitor,"target \(ipv6.debugDescription) status improved to \(status)")
        }
        if oldstatus == .Yellow && status == .Green {
            if lastAlertStatus == .Red {
                if let map = mapDelegate {
                    DLog.log(.mail, "Adding email alert for \(ipv6.debugDescription)")
                    let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv6.debugDescription, comment: comment, type: self.type, newStatus: .Green)
                    for emailAddress in map.emailAlerts {
                        appDelegate.pendNotification(emailAddress: emailAddress, notification: notification)
                    }
                }
            }
            lastAlertStatus = .Green
        }
    }
}
