//
//  AppDelegate.swift
//  Network Mom
//
//  Created by Darrell Root on 11/2/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

// File extension glossary:
// .mom1: A single map file
// .mom2: A full export of all maps

import Cocoa
import Network
import AppKit
import HeliumLogger
import LoggerAPI
import DLog
import Security

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    enum CodingKeys: String, CodingKey {
        case maps
    }
    var maps: [MapWindowController] = [] {
        didSet {
            for (index,map) in maps.enumerated() {
                map.mapIndex = index
            }
        }
    }
    var emails: [String:EmailAddress] = [:]

    public var ping4Socket: CFSocket?
    public var ping6Socket: CFSocket?
    private var socket4Source: CFRunLoopSource?
    private var socket6Source: CFRunLoopSource?
    var emailServerController: EmailServerController!
    var addEmailRecipientController: AddEmailRecipientController!
    var showLogController: ShowLogController!
    var emailConfiguration: EmailConfiguration?
    let defaults = UserDefaults.standard
    
    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func deleteMap(index: Int, name: String) {
        DLog.log(.dataIntegrity,"delete map requested index \(index) name \(name)")
        if index >= maps.count {
            DLog.log(.dataIntegrity,"error map index out of range aborting delete")
            return
        }
        if maps[index].name != name {
            DLog.log(.dataIntegrity,"error map name mismatch aborting delete")
            return
        }
        maps[index].close()
        maps.remove(at: index)
        fixMapIndex()
    }
    @IBAction func importMap(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mom1"]
        openPanel.begin { ( result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    DLog.log(.dataIntegrity,"opening from \(url.debugDescription)")
                    self.importData(url: url)
                }
            } else {
                DLog.log(.dataIntegrity,"open selection not successful")
            }
        }
    }
    @IBAction func configureEmailServer(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"Configure Email Server selected")
        emailServerController = EmailServerController()
        emailServerController.showWindow(self)
    }
    @IBAction func configureEmailRecipient(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"Configure Email Recipient selected")
        addEmailRecipientController = AddEmailRecipientController()
        addEmailRecipientController.showWindow(self)
    }

    @IBAction func importFullConfiguration(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mom2"]
        openPanel.begin { ( result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    DLog.log(.dataIntegrity,"opening from \(url.debugDescription)")
                    self.restoreAllConfig(url)
                }
            } else {
                DLog.log(.dataIntegrity,"open selection not successful")
            }
        }

    }
    func importData(url: URL) {
        if let data = try? Data(contentsOf: url) {
            let decoder = PropertyListDecoder()
            var importedMap: MapWindowController? = nil
            do {
                importedMap = try decoder.decode(MapWindowController.self, from: data)
            } catch {
                DLog.log(.dataIntegrity,"error decoding map")
            }
            if let importedMap = importedMap {
                maps.append(importedMap)
                importedMap.showWindow(self)
            }
            fixMapIndex()
        }
    }
    
    func loadEmailPassword() {
        if let emailServerHostname = defaults.string(forKey: Constants.emailServerHostname), let emailServerUsername = defaults.string(forKey: Constants.emailServerUsername) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrServer as String: emailServerHostname,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
                kSecAttrProtocol as String: Constants.networkmom]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess else {
                DLog.log(.dataIntegrity,"Mail account keychain not found at startup, status \(status)")
                DLog.log(.mail,"Mail account keychain not found at startup, status \(status)")
                return
            }
            guard let existingItem = item as? [String : Any],
                let passwordData = existingItem[kSecValueData as String] as? Data,
                let keychainPassword = String(data: passwordData, encoding: String.Encoding.utf8),
                let keychainEmail = existingItem[kSecAttrAccount as String] as? String
                else {
                    DLog.log(.dataIntegrity,"Unexpected mail account keychain info found at startup")
                    DLog.log(.mail,"Unexpected mail account keychain info found at startup")
                    return
            }
            if keychainEmail != emailServerUsername {
                DLog.log(.dataIntegrity,"Mail account keychain info did not match userdefaults at startup")
                DLog.log(.mail,"Mail account keychain info did not match userdefaults at startup")
                return
            }
            emailConfiguration = EmailConfiguration(server: emailServerHostname, username: emailServerUsername, password: keychainPassword)
            DLog.log(.dataIntegrity,"Mail account password successfully restored from keychain at startup")
            DLog.log(.mail,"Mail account password successfully restored from keychain at startup")
        }
    }
    
    func fixMapIndex() {
        DLog.log(.dataIntegrity,"fixing ids in each map")
        for (index,map) in maps.enumerated() {
            map.mapIndex = index
        }
    }
    
    func showSaveAlert(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Exporting Configuration to \(url) Failed"
        alert.informativeText = "Check your disk space and access permissions"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    @IBAction func exportFullConfiguration(_ sender: NSMenuItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["mom2"]
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    _ = self.exportFullConfig(url: url)
                }
            } else {
                DLog.log(.dataIntegrity,"File selection not successful")
            }
        }
    }
    
    func exportFullConfig(url: URL) -> Bool {
        DLog.log(.dataIntegrity,"saving to \(url.debugDescription)")
        var success = true
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(self.maps)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            DLog.log(.dataIntegrity,"error writing data to \(url)")
            self.showSaveAlert(url: url)
            success = false
        }
        return success
    }
    func saveAllConfig(_ sender: Any) -> Bool {
        // we also save 2 copies of our data.  The 2nd copy only gets saved if the first save is successful.
        DLog.log(.dataIntegrity,"saving all config")
        let dataUrl1 = documentsDirectory().appendingPathComponent("autosavedata1.mom2")
        let dataUrl2 = documentsDirectory().appendingPathComponent("autosavedata2.mom2")
        let successfulFirstSave = exportFullConfig(url: dataUrl1)
        var successfulSecondSave = false
        if successfulFirstSave {
            successfulSecondSave = exportFullConfig(url: dataUrl2)
        }
        return successfulSecondSave
    }
    
    @IBAction func showLogMenu(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"show log menu")
        showLogController = ShowLogController()
        showLogController.showWindow(self)
    }
    @IBAction func restoreAllConfig(_ sender: Any) {
        DLog.log(.dataIntegrity,"restoring all config")
        loadEmailPassword()
        let decoder = PropertyListDecoder()
        let dataUrl2 = documentsDirectory().appendingPathComponent("autosavedata2.mom2")
        DLog.log(.dataIntegrity,"restoring data from \(dataUrl2)")
        if let data = try? Data(contentsOf: dataUrl2) {
            if let maps = try? decoder.decode([MapWindowController].self, from: data) {
                self.maps = self.maps + maps
            }
            for map in maps {
                DLog.log(.dataIntegrity,"map name \(map.name)")
                map.showWindow(self)
            }
            fixMapIndex()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //let newMap = MapWindowController(name: "Default", mapIndex: maps.count)
        //maps.append(newMap)
        //maps[0].showWindow(self)
        //HeliumLogger.use()
        //Log.warning("this is a log test")
        DLog.log(.userInterface,"DLog.log test")
        restoreAllConfig(self)
        
        if maps.count == 0 {
            // initial launch
            let newMap = MapWindowController(name: "Default", mapIndex: maps.count)
            maps.append(newMap)
            maps[0].showWindow(self)
        }
        var context = CFSocketContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(),retain: nil, release: nil, copyDescription: nil)
        
        self.ping6Socket = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_DGRAM, 58,CFSocketCallBackType.dataCallBack.rawValue, {socket, type, address, data, info in
            //type is CFSocketCallBackType
            guard let socket = socket, let address = address, let data = data, let info = info else { return }
            let nsdataAddress: NSData = address
            var addr6 = sockaddr_in6()
            nsdataAddress.getBytes(&addr6, length: MemoryLayout<sockaddr_in6>.size)
            let typedData = data.bindMemory(to: UInt16.self, capacity: 80)
            let replyid = CFSwapInt16(typedData.advanced(by: 26).pointee)
            let replysequence = CFSwapInt16(typedData.advanced(by: 27).pointee)
            DLog.log(.monitor,"got ipv6 packet from \(addr6.string) id \(replyid) sequence \(replysequence)")
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            if let ipv6 = IPv6Address(addr6.string) {
                appDelegate.receivedPing6(ipv6: ipv6, sequence: replysequence, id: replyid)
            } else {
                DLog.log(.monitor,"failed to create ipv6 address from \(addr6.string)")
            }
            
        }, &context)
        socket6Source = CFSocketCreateRunLoopSource(nil, ping6Socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), socket6Source, .commonModes)
        
        self.ping4Socket = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_DGRAM, IPPROTO_ICMP,CFSocketCallBackType.dataCallBack.rawValue, {socket, type, address, data, info in
            //type is CFSocketCallBackType
            guard let socket = socket, let address = address, let data = data, let info = info else { return }
            let typedData = data.bindMemory(to: UInt8.self, capacity: 80)
            let sourceOctet1 = typedData.advanced(by: 60).pointee
            let sourceOctet2 = typedData.advanced(by: 61).pointee
            let sourceOctet3 = typedData.advanced(by: 62).pointee
            let sourceOctet4 = typedData.advanced(by: 63).pointee
            let idHighByte = typedData.advanced(by: 72).pointee
            let idLowByte = typedData.advanced(by: 73).pointee
            let sequenceHighByte = typedData.advanced(by: 74).pointee
            let sequenceLowByte = typedData.advanced(by: 75).pointee
            let sequence = UInt16(sequenceHighByte) * 256 + UInt16(sequenceLowByte)
            let id = UInt16(idHighByte) * 256 + UInt16(idLowByte)
            DLog.log(.monitor,"received icmp from \(sourceOctet1).\(sourceOctet2).\(sourceOctet3).\(sourceOctet4) id \(id)")
            let sourceIP: UInt32 = UInt32(sourceOctet1) * 256 * 256 * 256 + UInt32(sourceOctet2) * 256 * 256 + UInt32(sourceOctet3) * 256 + UInt32(sourceOctet4)
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.receivedPing4(ip: sourceIP, sequence: sequence, id: id)
            //}
            return
        }, &context)
        socket4Source = CFSocketCreateRunLoopSource(nil, ping4Socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), socket4Source, .commonModes)

    }
    
/*
    then calls the delegate’s applicationShouldTerminate(_:) method. If applicationShouldTerminate(_:) returns NSApplication.TerminateReply.terminateCancel, the termination process is aborted and control is handed back to the main event loop. If the method returns NSApplication.TerminateReply.terminateLater, the app runs its run loop in the modalPanel mode until the reply(toApplicationShould
*/
    func applicationWillTerminate(_ aNotification: Notification) {
        _ = saveAllConfig(self)
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Do you really want to quit Network Mom?"
        alert.informativeText = "Shutting down Network Mom will stop all monitoring, alerts, and data collection"
        alert.addButton(withTitle: "Cancel Exit")
        alert.addButton(withTitle: "Confirm Exit")
        let response = alert.runModal()
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            DLog.log(.userInterface,"first button return")
            return NSApplication.TerminateReply.terminateCancel
        case NSApplication.ModalResponse.alertSecondButtonReturn:
            DLog.log(.userInterface,"second button return")
            return NSApplication.TerminateReply.terminateNow
        default:
            DLog.log(.userInterface,"ERROR: unexpected response \(response)")
            return NSApplication.TerminateReply.terminateLater
        }
    }
    @IBAction func newMap(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"New Map Selected")
        let newmap = MapWindowController(name: "New", mapIndex: maps.count)
        maps.append(newmap)
        maps.last?.showWindow(self)
    }
}
extension AppDelegate: ReceivedPing4Delegate {
    func receivedPing4(ip: UInt32, sequence: UInt16, id: UInt16) {
        if id < maps.count {
            maps[Int(id)].receivedPing4(ip: ip, sequence: sequence, id: id)
        }
    }
    func receivedPing6(ipv6: IPv6Address, sequence: UInt16, id: UInt16) {
        if id < maps.count {
            maps[Int(id)].receivedPing6(ipv6: ipv6, sequence: sequence, id: id)
        }
    }
}

protocol ReceivedPing4Delegate: class {
    func receivedPing4(ip: UInt32, sequence: UInt16, id: UInt16)
}
protocol ReceivedPing6Delegate: class {
    func receivedPing6(ipv6: IPv6Address, sequence: UInt16, id: UInt16)
}

struct FileVersion: Codable {
    enum CodingKeys: String, CodingKey {
        case version
    }
    var version: Int
}
