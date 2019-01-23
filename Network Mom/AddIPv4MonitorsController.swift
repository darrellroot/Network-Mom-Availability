//
//  AddIPv4MonitorsController.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/22/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class AddIPv4MonitorsController: NSWindowController, HostAddressQueryDelegate {
    

    var delegate: MapWindowController!
    
    var addressQueries: [HostAddressQuery] = []
    var added = ""
    var alreadyMonitored = ""
    var invalid = ""
    var comments: [String:String] = [:]
    
    @IBOutlet var textView: NSTextView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AddIPv4MonitorsController")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        textView.string = """
        //Replace this text with a list of hostnames to monitor with IPv4
        //Valid import Formats for each line:
        HOSTNAME,COMMENT
        HOSTNAME
        //Examples:
        www.hostname.com,My Apple TV
        www.hostname.com
        //Do not include any commas in the comment
        """
    }
    
    @IBAction func importButton(_ sender: NSButton) {
        for query in addressQueries {
            query.cancel()
        }
        addressQueries = []
        let lines = textView.string.lines
        comments = [:]
        self.added = "//Added the following monitors:\n"
        self.alreadyMonitored = "//IPs already monitored:\n"
        invalid = "//Invalid lines or non-IPv4 addresses:\n"
        for line in lines {
            if line.starts(with: "//") {
                print("comment detected \(line)")
                continue
            }
            var hostname: String? = nil
            let components = line.split(separator: ",")
            if components.count == 0 {
                DLog.log(.userInterface,"Import invalid line \(line)")
                continue
            }
            if components.count > 2 {
                self.invalid += line + "\n"
                continue
            }
            if components.count == 2 {
                comments[String(components[0])] = String(components[1])
                // using URL creation to validate hostname
                if let url = URL(string: "http://\(components[0])") {
                    hostname = url.host
                } else {
                    self.invalid += line + "\n"
                    continue
                }
            }
            if components.count == 1 {
                if let url = URL(string: "http://\(components[0])") {
                    hostname = url.host
                } else {
                    self.invalid += "//Invalid line " + line + "\n"
                    continue
                }
            }
            if let hostname = hostname {
                self.addressQueries.append(HostAddressQuery(name: hostname))
                self.addressQueries.last?.delegate = self as HostAddressQueryDelegate
                self.addressQueries.last?.start()
            }
        }
        textView.string = added + alreadyMonitored + invalid
    }
    
    func didCompleteAddress(address: Data, query: HostAddressQuery) {
        let comment = comments[query.name]
        guard let possibleAddressString = numeric(for: address) else {
            invalid += "//\(query.name) DNS resolution not numeric\n"
            return
        }
        DLog.log(.dns,"\(query.name) address \(possibleAddressString)")
        guard let addressString = possibleAddressString.ipv4address else {
            invalid += "//\(query.name) \(possibleAddressString) not an IPv4 address\n"
            return
        }
        guard !delegate.alreadyMonitored(ipv4String: addressString) else {
            alreadyMonitored += "//\(query.name) \(addressString) already monitored\n"
            return
        }
        if let newMonitor = MonitorIPv4(ipv4string: addressString, hostname: query.name, comment: comment) {
            delegate?.addIPv4Monitor(monitor: newMonitor)
            added += "//Added Monitor \(query.name) address \(addressString) comment \(comment ?? "none"))"
        } else {
            invalid += "Unknown error adding monitor \(query.name) address \(addressString) comment \(comment ?? "none"))"
        }
    }
    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery) {
        for address in addresses {
            didCompleteAddress(address: address, query: query)
        }
        
        if let idx = addressQueries.index(where: { $0 === query }) {
            addressQueries.remove(at: idx)
        }

        textView.string = added + alreadyMonitored + invalid
    }
    
    func didComplete(error: Error, hostAddressQuery query: HostAddressQuery) {
        DLog.log(.dns,"DNS query error \(error)")
        invalid += "\(query.name) DNS query error \(error)"
        if let idx = addressQueries.index(where: { $0 === query }) {
            addressQueries.remove(at: idx)
        }
    }

    func windowWillClose(_ notification: Notification) {
        for query in addressQueries {
            query.cancel()
        }
        delegate.addIPv4MonitorsControllers.remove(object: self)
    }

    func numeric(for address: Data) -> String? {
        var name = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let saLen = socklen_t(address.count)
        let success = address.withUnsafeBytes { (sa: UnsafePointer<sockaddr>) in
            return getnameinfo(sa, saLen, &name, socklen_t(name.count), nil, 0, NI_NUMERICHOST | NI_NUMERICSERV) == 0
        }
        guard success else {
            return nil
        }
        return String(cString: name)
    }

}
