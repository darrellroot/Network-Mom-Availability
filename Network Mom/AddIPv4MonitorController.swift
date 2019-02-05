//
//  AddIPv4MonitorController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/2/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa
import DLog

class AddIPv4MonitorController: NSWindowController {

    weak var delegate: AddMonitorDelegate?
    var cferror: UnsafeMutablePointer<CFStreamError>?
    var comment: String?  // candidate comment for monitor comment field

    var validatedIP: String? {
        didSet {
            if validatedIP == nil {
                addMonitorButtonOutlet.isEnabled = false
                ipv4ValidatedField.stringValue = "Not Validated"
            } else {
                if delegate?.alreadyMonitored(ipv4String: validatedIP!) == true {
                    ipv4ValidatedField.stringValue = "Already Monitored"
                    addMonitorButtonOutlet.isEnabled = false
                } else {
                    addMonitorButtonOutlet.isEnabled = true
                    ipv4ValidatedField.stringValue = validatedIP!
                }
            }
        }
    }
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
    var addressQueries: [HostAddressQuery] = []
    
    @IBOutlet weak var ipv4InputField: NSTextField!
    
    @IBOutlet weak var ipv4ValidatedField: NSTextField!
    
    @IBOutlet weak var validatedHostnameField: NSTextField!

    @IBOutlet weak var addMonitorButtonOutlet: NSButton!
    
    @IBAction func cancelButton(_ sender: NSButton) {
        cancelHostResolution()
        dismissWithModalResponse(response: NSApplication.ModalResponse.cancel)
        //self.close()
    }
    
    @IBAction func addButtonPressed(_ sender: NSButton) {
        cancelHostResolution()
        if let validatedIP = validatedIP {
            DLog.log(.userInterface,"adding new monitor \(validatedIP.debugDescription)")
            if let newMonitor = MonitorIPv4(ipv4string: validatedIP, hostname: validatedHostname, comment: comment) {
                delegate?.addIPv4Monitor(monitor: newMonitor)
            }
        }
        dismissWithModalResponse(response: NSApplication.ModalResponse.OK)
    }
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AddIPv4MonitorController")
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
    
    /* Does not work, apples help system is broken for anchors
    @IBAction func showHelp(_ sender: NSButton) {
        let helpBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? NSHelpManager.BookName
        print("helpbookname \(helpBookName)")
        //NSHelpManager.shared.openHelpAnchor("AddingMonitor", inBook: helpBookName)
        //NSHelpManager.shared.openHelpAnchor("Page17.html", inBook: nil)
        NSHelpManager.shared.find("AddingMonitor", inBook: "net.networkmom.NetworkMomAvailability.help")
        //NSHelpManager.shared.openHelpAnchor("AddingMonitor", inBook: NSHelpManager.BookName("net.networkmom.NetworkMomAvailability.help"))
    }*/
    
    override func windowDidLoad() {
        super.windowDidLoad()
        ipv4ValidatedField.stringValue = "Not Validated"
    }

    @IBAction func ipv4InputFieldPressed(_ sender: NSTextField) {
        comment = nil
        cancelHostResolution()
        validateInputField()
    }

    func validateInputField() {
        validatedIP = nil
        validatedHostname = nil
        validatedIP = ipv4InputField.stringValue.ipv4address
        if validatedIP != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.possibleHostname = nil
                if let validatedIP = self?.validatedIP {
                    DLog.log(.dns,"starting host resolution \(validatedIP)")
                    let host = Host(address: validatedIP)
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
            self.addressQueries.append(HostAddressQuery(name: ipv4InputField.stringValue))
            self.addressQueries.last?.delegate = self
            self.addressQueries.last?.start()
            cfResolutionInProgress = true
        } // if let validatedIP
    }


}

extension AddIPv4MonitorController: HostAddressQueryDelegate {
    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery) {
        DLog.log(.dns,"DNS query completed")
        cfResolutionInProgress = false
        for address in addresses {
            if let addressString = numeric(for: address) {
                DLog.log(.dns,"\(query.name) address \(addressString)")
                if let addressString = addressString.ipv4address {
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
