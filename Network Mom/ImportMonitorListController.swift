//
//  ImportMonitorListController.swift
//  Network Mom
//
//  Created by Darrell Root on 12/9/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog
import Network

class ImportMonitorListController: NSWindowController, NSWindowDelegate {

    var delegate: MapWindowController!
    
    @IBOutlet var textView: NSTextView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ImportMonitorListController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        textView.string = """
    //Replace this text with a list of monitors to import
    //We assume your hostname is correct
    //We monitor by IP address
    //Valid import Formats for each line:
    IP_ADDRESS,HOSTNAME,COMMENT
    IP_ADDRESS,HOSTNAME
    IP_ADDRESS
    //Examples:
    192.168.0.25,www.hostname.com,My Apple TV
    192.168.0.16,www.hostname.com
    192.168.0.10
    2601:0:4802:0:1cf5:0:b441:0,www.nodomain.com
    2620::90d9:73ff:0:fe9a
    //Do not include any commas in the comment
    """
    }
    
    @IBAction func importButton(_ sender: NSButton) {
        let lines = textView.string.lines
        var added = "Added the following monitors:\n"
        var alreadyMonitored = "IPs already monitored:\n"
        var invalid = "Invalid lines:\n"
        for line in lines {
            var hostname: String? = nil
            var comment: String? = nil
            let components = line.split(separator: ",")
            if components.count == 0 {
                DLog.log(.userInterface,"Import invalid line \(line)")
                continue
            }
            if components.count > 3 {
                invalid += line + "\n"
                continue
            }
            if components.count > 1 {
                // using URL creation to validate hostname
                if let url = URL(string: "http://\(components[1])") {
                    hostname = url.host
                }
            }
            if components.count > 2 {
                comment = String(components[2])
            }
            let candiateIP = String(components[0])
            if let ipv4string = candiateIP.ipv4address {
                if (delegate.alreadyMonitored(ipv4String: ipv4string)) {
                    alreadyMonitored += line + "\n"
                    continue
                }
                if let newMonitor = MonitorIPv4(ipv4string: ipv4string, hostname: hostname, latencyEnabled: true) {
                    newMonitor.comment = comment
                    delegate?.addIPv4Monitor(monitor: newMonitor)
                    added += line + "\n"
                } else {
                    invalid += line + "\n"
                }
                continue
            }
            if let ipv6 = IPv6Address(candiateIP) {
                if delegate.alreadyMonitored(ipv6: ipv6) {
                    alreadyMonitored += line + "\n"
                    continue
                }
                if let newMonitor = MonitorIPv6(ipv6: ipv6, hostname: hostname, latencyEnabled: true) {
                    newMonitor.comment = comment
                    delegate.addIPv6Monitor(monitor: newMonitor)
                    added += line + "\n"
                    continue
                } else {
                    invalid += line + "\n"
                }
                continue
            }
            invalid += line + "\n"
        }
        textView.string = added + alreadyMonitored + invalid
    }
    func windowWillClose(_ notification: Notification) {
        delegate.importMonitorListControllers.remove(object: self)
    }
}
