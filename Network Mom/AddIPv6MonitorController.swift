//
//  AddIPv6Monitor.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/11/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Cocoa
import Network
import DLog

class AddIPv6MonitorController: NSWindowController {
    
    weak var delegate: AddMonitorDelegate?
    var cferror: UnsafeMutablePointer<CFStreamError>?
    var comment: String?  // candidate comment for monitor comment field
    
    var validatedIP: IPv6Address? {
        didSet {
            if validatedIP == nil {
                addMonitorButtonOutlet.isEnabled = false
                ipv6ValidatedField.stringValue = "Not Validated"
            } else {
                if delegate?.alreadyMonitored(ipv6: validatedIP!) == true {
                    ipv6ValidatedField.stringValue = "Already Monitored"
                    addMonitorButtonOutlet.isEnabled = false
                } else {
                    addMonitorButtonOutlet.isEnabled = true
                    ipv6ValidatedField.stringValue = validatedIP!.debugDescription
                }
            }
        }
    }
    var latencyEnabled: Bool = false
    var possibleHostname: String?
    var validatedHostname: String? {
        didSet {
            if let validatedHostname = validatedHostname {
                validatedHostnameField.stringValue = validatedHostname
            } else {
                validatedHostnameField.stringValue = "Not Validated"
            }
        }
    }

    var cfhost: CFHost?
    var cfResolutionInProgress: Bool = false
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var latencyButtonOutlet: NSPopUpButton!

    var addressQueries: [HostAddressQuery] = []
    
    @IBOutlet weak var ipv6InputField: NSTextField!
    
    @IBOutlet weak var ipv6ValidatedField: NSTextField!
    
    @IBOutlet weak var validatedHostnameField: NSTextField!
    
    @IBOutlet weak var addMonitorButtonOutlet: NSButton!

    @IBAction func cancelButton(_ sender: NSButton) {
        cancelHostResolution()
        dismissWithModalResponse(response: NSApplication.ModalResponse.cancel)
        //self.close()
    }
    
    @IBAction func latencyButton(_ sender: NSPopUpButton) {
    }
    
    @IBAction func addButtonPressed(_ sender: NSButton) {
        cancelHostResolution()
        switch latencyButtonOutlet.indexOfSelectedItem {
        case 0: latencyEnabled = false
        case 1: latencyEnabled = true
        // should not get to default case
        default: latencyEnabled = false
        }
        if let validatedIP = validatedIP {
            DLog.log(.userInterface,"adding new monitor \(validatedIP.debugDescription) with latency \(latencyEnabled)")
            if let newMonitor = MonitorIPv6(ipv6: validatedIP, hostname: validatedHostname, latencyEnabled: latencyEnabled) {
                newMonitor.comment = comment
                DLog.log(.userInterface,"set new monitor comment \(String(describing: comment))")
                delegate?.addIPv6Monitor(monitor: newMonitor)
            }
        }
        dismissWithModalResponse(response: NSApplication.ModalResponse.OK)
    }

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AddIPv6MonitorController")
        //return NSNib.Name("blah")
    }
    
    func cancelHostResolution() {
        if cfResolutionInProgress, let cfhost = cfhost {
            CFHostCancelInfoResolution(cfhost, .addresses)
        }
        cfResolutionInProgress = false
    }

    func dismissWithModalResponse(response: NSApplication.ModalResponse) {
        window!.sheetParent!.endSheet(window!, returnCode: response)
    }
    
    override func windowDidLoad() {
        DLog.log(.userInterface,"loading AddIPv6MonitorController window")
        super.windowDidLoad()
        ipv6ValidatedField.stringValue = "Not Validated"
    }
    @IBAction func ipv6InputFieldPressed(_ sender: NSTextField) {
        cancelHostResolution()
        validateInputField()
    }
    func MyHostClientCallBack() {
        
    }
    
    func validateInputField() {
        comment = nil
        validatedIP = IPv6Address(ipv6InputField.stringValue)
        if validatedIP != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.possibleHostname = nil
                if let validatedIP = self?.validatedIP {
                    DLog.log(.dns,"starting host resolution \(validatedIP)")
                    let host = Host(address: validatedIP.debugDescription)
                    DLog.log(.dns,"completed host resolution \(String(describing: host.name))")
                    self?.possibleHostname = host.name
                    DispatchQueue.main.async {
                        if let possibleHostname = self?.possibleHostname {
                            self?.validatedHostname = possibleHostname
                        }
                    }
                }
            }
        } else {
            self.addressQueries.append(HostAddressQuery(name: ipv6InputField.stringValue))
            self.addressQueries.last?.delegate = self
            self.addressQueries.last?.start()
            cfResolutionInProgress = true
        }
    }
}
extension AddIPv6MonitorController: HostAddressQueryDelegate {
    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery) {
        DLog.log(.dns,"DNS query completed")
        cfResolutionInProgress = false
        for address in addresses {
            if let addressString = numeric(for: address) {
                DLog.log(.dns, "DNS\(query.name) address \(addressString)")
                if let addressString = IPv6Address(addressString) {
                    validatedIP = addressString
                    validatedHostname = query.name
                }
            }
        }
    }
    
    func didComplete(error: Error, hostAddressQuery query: HostAddressQuery) {
        DLog.log(.dns,"DNS query error \(error)")
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
