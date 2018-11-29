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

class MonitorIPv6: Monitor, Codable {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    enum CodingKeys: String, CodingKey {
        case ipv6
        case latencyEnabled
        case hostname
        case comment
        case availability
        case latency
        case viewFrame
    }

    var ipv6: IPv6Address
    
    //var ipv6string: String
    var sockaddrin: sockaddr_in6
    var lastPingID: UInt16 = 0      //last ping id sent
    var lastPingSequence: UInt16 = 0     //last ping id sent
    let type: MonitorEnumeration = .MonitorIPv6
    //let ipv4: UInt32
    var lastIdReceived: UInt16 = 0
    var lastSequenceReceived: UInt16 = 0
    var latencyEnabled = false
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
    var latency: RRDGauge?
    var viewFrame: NSRect?

    weak var viewDelegate: DragMonitorView?
    weak var mapDelegate: MapWindowController?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.ipv6.debugDescription, forKey: .ipv6)
        try container.encode(self.latencyEnabled, forKey: .latencyEnabled)
        try container.encode(self.hostname, forKey: .hostname)
        try container.encode(self.comment, forKey: .comment)
        try container.encode(self.availability, forKey: .availability)
        try container.encode(self.latency, forKey: .latency)
        try? container.encode(self.viewFrame, forKey: .viewFrame)
    }
    required init(from decoder: Decoder) throws {
        // after decoder need to fix mapDelegate and viewDelegate
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ipv6string = try container.decode(String.self, forKey: .ipv6)
        latencyEnabled = try container.decode(Bool.self, forKey: .latencyEnabled)
        hostname = try container.decode(String?.self, forKey: .hostname)
        comment = try container.decode(String?.self, forKey: .comment)
        availability = try container.decode(RRDGauge.self, forKey: .availability)
        latency = try container.decode(RRDGauge?.self, forKey: .latency)
        viewFrame = try container.decode(NSRect?.self, forKey: .viewFrame)
        if let ipv6 = IPv6Address(ipv6string) {
            self.ipv6 = ipv6
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.ipv6,
                in: container,
                debugDescription: "ipv6 string not formatted correctly"
            )
        }
        if let sockaddrin = sockaddr_in6(ipv6: ipv6, port: 0) {
            self.sockaddrin = sockaddrin
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.ipv6,
                in: container,
                debugDescription: "ipv6 string not formatted correctly"
            )
        }
    }
    

    init?(ipv6: IPv6Address, hostname: String?, latencyEnabled: Bool) {
        self.hostname = hostname
        self.latencyEnabled = latencyEnabled
        self.ipv6 = ipv6
        guard let tmpsockaddrin = sockaddr_in6(ipv6: ipv6, port: 0) else { return nil }
        self.sockaddrin = tmpsockaddrin
        availability = RRDGauge()
        if latencyEnabled {
            latency = RRDGauge()
        }
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
        if latencyEnabled { pingSentDate = Date() }
        DLog.log(.monitor,"sent ping to \(ipv6.debugDescription)")
    }
    public func latencyStatus() -> MonitorStatus? {
        if !latencyEnabled {
            return nil
        }
        if let currentLatency = latency?.lastFiveMinute?.value, let yesterdayLatency = latency?.lastThirtyMinute?.value {   // change to lastDay when we go production
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
    func receivedPing(receivedip: IPv6Address, sequence: UInt16, id: UInt16) {
        DLog.log(.monitor,"\(self.ipv6.debugDescription) received ping")
        guard receivedip == self.ipv6 && sequence == lastPingSequence && id == lastPingID else {
            DLog.log(.monitor,"icmp return mismatch sent \(ipv6.debugDescription) seq \(lastPingSequence) id \(lastPingID)")
            DLog.log(.monitor,"icmp return mismatch received \(receivedip) seq \(sequence) id \(id)")
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
