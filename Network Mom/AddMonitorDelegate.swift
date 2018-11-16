//
//  AddMonitorProtocol.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/12/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//
import Network

protocol AddMonitorDelegate: class {
    func addIPv4Monitor(monitor: MonitorIPv4)
    func addIPv6Monitor(monitor: MonitorIPv6)
    func alreadyMonitored(ipv4String: String) -> Bool
    func alreadyMonitored(ipv6: IPv6Address) -> Bool
}
