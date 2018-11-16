//
//  MonitorProtocol.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/14/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation

protocol Monitor: AnyObject, Codable {
    var type: MonitorEnumeration { get }
    var label: String { get }
    var status: MonitorStatus { get }
    var hostname: String? { get set }
    var comment: String? { get set }
    var viewDelegate: DragMonitorView? { get set }
    var availability: RRDGauge { get }
    var latencyEnabled: Bool { get }
    var latency: RRDGauge? { get }
    func latencyStatus() -> MonitorStatus?
    var viewFrame: NSRect? { get set }
}
