//
//  MonitorIPv4.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/12/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation
import DLog

class MonitorIPv4: Monitor {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var coreMonitorIPv4: CoreMonitorIPv4?
    var ipv4string: String
    var sockaddrin: sockaddr_in
    var lastPingID: UInt16 = 0      //last ping id sent
    var lastPingSequence: UInt16 = 0     //last ping id sent
    let type: MonitorEnumeration = .MonitorIPv4
    let ipv4: UInt32
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
    var saveTest: Bool?
    
    weak var viewDelegate: DragMonitorView?
    weak var mapDelegate: MapWindowController?

    init?(coreData: CoreMonitorIPv4) {
        self.coreMonitorIPv4 = coreData
        self.ipv4 = UInt32(coreData.ipv4)
        self.ipv4string = UInt32(coreData.ipv4).ipv4string
        guard let tmpsockaddrin = sockaddr_in(ipv4string: UInt32(coreData.ipv4).ipv4string, port: 0) else { return nil }
        self.sockaddrin = tmpsockaddrin
        self.hostname = coreData.hostname
        self.comment = coreData.comment
        self.viewFrame = NSRect(x: CGFloat(coreData.frameX), y: CGFloat(coreData.frameY), width: CGFloat(coreData.frameWidth), height: CGFloat(coreData.frameHeight))
        do {
            let fiveMinCoreData = coreData.availabilityFiveMinuteData ?? []
            let fiveMinCoreTime = coreData.availabilityFiveMinuteTimestamp ?? []
            let oneHourCoreData = coreData.availabilityOneHourData ?? []
            let oneHourCoreTime = coreData.availabilityOneHourTimestamp ?? []
            let dayCoreData = coreData.availabilityDayData ?? []
            let dayCoreTime = coreData.availabilityDayTimestamp ?? []
            availability = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, oneHourData: oneHourCoreData, oneHourTime: oneHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        }
        do {
            let fiveMinCoreData = coreData.latencyFiveMinuteData ?? []
            let fiveMinCoreTime = coreData.latencyFiveMinuteTimestamp ?? []
            let oneHourCoreData = coreData.latencyOneHourData ?? []
            let oneHourCoreTime = coreData.latencyOneHourTimestamp ?? []
            let dayCoreData = coreData.latencyDayData ?? []
            let dayCoreTime = coreData.latencyDayTimestamp ?? []
            latency = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, oneHourData: oneHourCoreData, oneHourTime: oneHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        }
    }
    func licenseExpired() {
        self.status = .Blue
        self.lastAlertStatus = .Blue
    }
    func writeCoreData() {
        guard let coreData = coreMonitorIPv4 else {
            DLog.log(.dataIntegrity,"Warning: no coreMonitorIPv4 core data structure in MonitorIPv4 \(ipv4string)")
            return
        }
        coreData.frameHeight = Float(viewFrame?.height ?? 200.0)
        coreData.frameWidth = Float(viewFrame?.width ?? 200.0)
        coreData.frameX = Float(viewFrame?.minX ?? 40.0)
        coreData.frameY = Float(viewFrame?.minY ?? 40.0)
        coreData.comment = self.comment
        coreData.hostname = self.hostname
        coreData.ipv4 = Int64(self.ipv4)
        
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
            case .OneHour:
                coreData.availabilityOneHourTimestamp = timestamps
                coreData.availabilityOneHourData = values
            case .OneDay:
                coreData.availabilityDayTimestamp = timestamps
                coreData.availabilityDayData = values
            }
            DLog.log(.dataIntegrity, "Monitor IPv4 \(ipv4string) availability wrote dataType \(dataType) \(values.count) entries")
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
            case .OneHour:
                coreData.latencyOneHourTimestamp = timestamps
                coreData.latencyOneHourData = values
            case .OneDay:
                coreData.latencyDayTimestamp = timestamps
                coreData.latencyDayData = values
            }
            DLog.log(.dataIntegrity, "Monitor IPv4 \(ipv4string) latency wrote dataType \(dataType) \(values.count) entries")
        }
    }
    var label: String {
        var label = ""
        if let hostname = hostname {
            label += hostname
        }
        label = label + "\n" + ipv4string
        if let comment = comment {
            label = label + "\n" + comment
        }
        return label
    }


    init?(ipv4string: String, hostname: String?, comment: String?) {
        self.hostname = hostname
        self.comment = comment
        let tmpstring = ipv4string.ipv4address
        if tmpstring == nil { return nil }  // initialization failed
        self.ipv4string = tmpstring!
        guard let tmpsockaddrin = sockaddr_in(ipv4string: self.ipv4string, port: 0) else { return nil }
        self.sockaddrin = tmpsockaddrin
        if let ipv4 = ipv4string.ipv4 {
            self.ipv4 = ipv4
        } else {
            return nil
        }
        availability = RRDGauge()
        latency = RRDGauge()
        coreMonitorIPv4 = CoreMonitorIPv4(context: appDelegate.managedContext)
        self.writeCoreData()
    }
    
    deinit {
        DLog.log(.dataIntegrity,"deallocating ipv4 monitor \(ipv4string)")
        if let coreMonitorIPv4 = self.coreMonitorIPv4 {
            DLog.log(.dataIntegrity,"deleting ipv4 nsmanaged object self.ipv4string")
            coreMonitorIPv4.managedObjectContext?.delete(coreMonitorIPv4)
        }
    }
    func sendPing(pingSocket: CFSocket?) {
        sendPing(pingSocket: pingSocket, id: 400)
    }
    func sendPing(pingSocket: CFSocket?, id: Int) {
        let pingID = UInt16(id)
        if lastPingID != lastIdReceived || lastPingSequence != lastSequenceReceived {
            let oldstatus = status
            status = status.worsen
            if oldstatus != status {
                DLog.log(.monitor,"target \(ipv4string) status worsened to \(status)")
            }
            if status != .Blue {
                // we don't count availability on devices which were never online
                availability.update(newData: 0.0)
                if let mapWindowController = mapDelegate {
                    mapWindowController.availability.update(newData: 0.0)
                }
            }
            if oldstatus == .Orange && status == .Red {
                if lastAlertStatus == .Green {
                    if let map = mapDelegate {
                        DLog.log(.mail, "Adding email alert for \(ipv4string)")
                        let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv4string, comment: comment, type: self.type, newStatus: .Red)
                        appDelegate.audioAlert()
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
        var myPacket = IcmpEchoRequest(id: pingID, sequence: lastPingSequence)
        let myPacketCFData = NSData(bytes: &myPacket, length: MemoryLayout<IcmpEchoRequest>.size) as CFData
        guard pingSocket != nil else { DLog.log(.monitor,"sendPing failed: socket nil"); return}
        let mySockCFData = NSData(bytes: &sockaddrin,length: MemoryLayout<sockaddr>.size) as CFData
        let socketError = CFSocketSendData(pingSocket, mySockCFData as CFData, myPacketCFData, 1)
        pingSentDate = Date()
        DLog.log(.monitor,"sent ping to \(ipv4string) socketError \(socketError)")
    }
    
    public func latencyStatus() -> MonitorStatus? {
        //if device is not responding to pings, latency display should be red
        if status == .Red {
            return MonitorStatus.Red
        }
        if status == .Blue {
            return MonitorStatus.Blue
        }
        var yesterdayLatency: Double? = nil
        if let tempLatency = latency.lastDay?.value {
            yesterdayLatency = tempLatency
        } else if let tempLatency = latency.lastOneHour?.value {
            yesterdayLatency = tempLatency
        }
        if let currentLatency = latency.lastFiveMinute?.value, let yesterdayLatency = yesterdayLatency {   // change to lastDay when we go production
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
    func receivedPing(ip: UInt32, sequence: UInt16, id: UInt16) {
        DLog.log(.monitor,"\(self.ipv4string) received ping")
        guard ip == self.ipv4 && sequence == lastPingSequence && id == lastPingID else {
            DLog.log(.monitor,"icmp return mismatch sent \(ipv4) seq \(lastPingSequence) id \(lastPingID)")
            DLog.log(.monitor,"icmp return mismatch received \(ip) seq \(sequence) id \(id)")
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
            DLog.log(.monitor,"target \(ipv4string) status improved to \(status)")
        }
        if oldstatus == .Yellow && status == .Green {
            if lastAlertStatus == .Red {
                if let map = mapDelegate {
                    DLog.log(.mail, "Adding email alert for \(ipv4string)")
                    let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv4string, comment: comment, type: self.type, newStatus: .Green)
                    for emailAddress in map.emailAlerts {
                        appDelegate.pendNotification(emailAddress: emailAddress, notification: notification)
                    }
                }
            }
            lastAlertStatus = .Green
        }
    }
}
