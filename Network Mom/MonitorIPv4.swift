//
//  MonitorIPv4.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/12/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation
import DLog

let latencyStaticThreshold = 10.0
let latencyPercentThresholdRed = 1.80
let latencyPercentThresholdOrange = 1.50
let latencyPercentThresholdYellow = 1.20

class MonitorIPv4: Monitor, Codable {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    enum CodingKeys: String, CodingKey {
        case ipv4string
        case ipv4
        case latencyEnabled
        case hostname
        case comment
        case availability
        case latency
        case viewFrame
        case saveTest
    }
    var ipv4string: String
    var sockaddrin: sockaddr_in
    var lastPingID: UInt16 = 0      //last ping id sent
    var lastPingSequence: UInt16 = 0     //last ping id sent
    let type: MonitorEnumeration = .MonitorIPv4
    let ipv4: UInt32
    var lastIdReceived: UInt16 = 0
    var lastSequenceReceived: UInt16 = 0
    var latencyEnabled = false
    private var pingSentDate: Date?
    var status: MonitorStatus = .Blue {
        didSet {
            viewDelegate?.needsDisplay = true
        }
    }
    var hostname: String?
    var comment: String? {
        didSet {
            viewDelegate?.updateFrame()
        }
    }
    var availability: RRDGauge
    var latency: RRDGauge?
    var viewFrame: NSRect?
    var saveTest: Bool?
    
    weak var viewDelegate: DragMonitorView?
    weak var mapDelegate: MapWindowController?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.ipv4string, forKey: .ipv4string)
        try container.encode(self.ipv4, forKey: .ipv4)
        try container.encode(self.latencyEnabled, forKey: .latencyEnabled)
        try container.encode(self.hostname, forKey: .hostname)
        try container.encode(self.comment, forKey: .comment)
        try container.encode(self.availability, forKey: .availability)
        try container.encode(self.latency, forKey: .latency)
        try? container.encode(self.viewFrame, forKey: .viewFrame)
        //try container.encode(self.saveTest, forKey: .saveTest)
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ipv4string = try container.decode(String.self, forKey: .ipv4string)
        ipv4 = try container.decode(UInt32.self, forKey: .ipv4)
        latencyEnabled = try container.decode(Bool.self, forKey: .latencyEnabled)
        hostname = try container.decode(String?.self, forKey: .hostname)
        comment = try container.decode(String?.self, forKey: .comment)
        availability = try container.decode(RRDGauge.self, forKey: .availability)
        latency = try container.decode(RRDGauge?.self, forKey: .latency)
        viewFrame = try container.decode(NSRect?.self, forKey: .viewFrame)
        if let saveTest = try? container.decode(Bool?.self, forKey: .saveTest) {
            self.saveTest = saveTest
        }
        
        if let sockaddrin = sockaddr_in(ipv4string: ipv4string, port: 0) {
            self.sockaddrin = sockaddrin
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.ipv4string,
                in: container,
                debugDescription: "ipv4 string not formatted correctly"
            )
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


    init?(ipv4string: String, hostname: String?, latencyEnabled: Bool) {
        self.hostname = hostname
        self.latencyEnabled = latencyEnabled
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
        if latencyEnabled {
            latency = RRDGauge()
        }
    }
    
    deinit {
        DLog.log(.dataIntegrity,"deallocating ipv4 monitor \(ipv4string)")
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
            }
            if oldstatus == .Orange && status == .Red {
                if let map = mapDelegate {
                    let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv4string, comment: comment, type: self.type, newStatus: .Red)
                    for emailAddress in map.emailAlerts {
                        appDelegate.pendNotification(emailAddress: emailAddress, notification: notification)
                    }
                }
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
        if latencyEnabled { pingSentDate = Date() }
        DLog.log(.monitor,"sent ping to \(ipv4string)")
    }
    
    public func latencyStatus() -> MonitorStatus? {
        if !latencyEnabled {
            return nil
        }
        var yesterdayLatency: Double? = nil
        if let tempLatency = latency?.lastDay?.value {
            yesterdayLatency = tempLatency
        } else if let tempLatency = latency?.lastThirtyMinute?.value {
            yesterdayLatency = tempLatency
        }
        if let currentLatency = latency?.lastFiveMinute?.value, let yesterdayLatency = yesterdayLatency {   // change to lastDay when we go production
            if currentLatency > yesterdayLatency * latencyPercentThresholdRed + latencyStaticThreshold {
                return MonitorStatus.Red
            }
            if currentLatency > yesterdayLatency * latencyPercentThresholdOrange + latencyStaticThreshold {
                return MonitorStatus.Orange
            }
            if currentLatency > yesterdayLatency * latencyPercentThresholdYellow + latencyStaticThreshold {
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
        if latencyEnabled, let pingSentDate = pingSentDate {
            let interval = Date().timeIntervalSince(pingSentDate) * 1000
            latency?.update(newData: interval)
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
            if let map = mapDelegate {
                let notification = EmailNotification(map: map.name, hostname: hostname, ip: ipv4string, comment: comment, type: self.type, newStatus: .Green)
                for emailAddress in map.emailAlerts {
                    appDelegate.pendNotification(emailAddress: emailAddress, notification: notification)
                }
            }
        }
    }
}
