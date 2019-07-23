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
import LoggerAPI
import DLog
import Security
import CoreData
import StoreKit

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
    var emails: [EmailAddress] = []
    //var coreEmails: [CoreEmailAddress] = []
    lazy var managedContext: NSManagedObjectContext! = coreDataStack.managedContext
    lazy var coreDataStack = CoreDataStack(modelName: "CoreDataModel")
//    var persistentContainer = NSPersistentContainer(name: "CoreDataModel")

    @IBOutlet weak var configureEmailServerOutlet: NSMenuItem!
    
    var lastSaveTimeElapsed: Double?
    
    public var ping4Socket: CFSocket?
    public var ping6Socket: CFSocket?
    private var socket4Source: CFRunLoopSource?
    private var socket6Source: CFRunLoopSource?
    var emailServerController: EmailServerController!
    var addEmailRecipientControllers: [AddEmailRecipientController] = []
    var deleteEmailRecipientControllers: [DeleteEmailRecipientController] = []
    var emailNotificationConfigurationReportControllers: [EmailNotificationConfigurationReportController] = []
    var manageEmailNotificationsControllers: [ManageEmailNotificationsController] = []
    var preferencesController: PreferencesController?
    var showLogControllers: [ShowLogController] = []
    var showStatisticsControllers: [ShowStatisticsController] = []
    var emailConfiguration: EmailConfiguration?
    let userDefaults = UserDefaults.standard
    var emailAlertTimer : Timer!
    var emailReportTimer : Timer!
    var currentSound: NSSound?
    var lastAudioAlert: Date?
    var audioAlertFrequency: Int {
        get {
            return userDefaults.integer(forKey: Constants.audioAlertFrequency)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.audioAlertFrequency)
        }
    }
    var audioName: String {
        get {
            return userDefaults.string(forKey: Constants.audioName) ?? Constants.systemBeep
        }
        set {
            userDefaults.set(newValue, forKey: Constants.audioName)
        }

    }
    
    
    @IBAction func aboutNetworkMom(_ sender: NSMenuItem) {
        let staticHtmlController = StaticHtmlController()
        staticHtmlController.resource = "about"
        staticHtmlController.showWindow(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DLog.log(.userInterface,"Application Did Finish Launching")
        restoreAllConfig(self)
        
        if audioName != Constants.systemBeep {
            if let audioURL = Bundle.main.url(forResource: audioName, withExtension: "") {
                DLog.log(.dataIntegrity,"Restored audio file \(audioName)")
                currentSound = NSSound(contentsOf: audioURL, byReference: false)
            } else {
                DLog.log(.dataIntegrity,"Unable to restore audio file \(audioName)")
            }
        }
        if maps.count == 0 {
            // initial launch
            let newMap = MapWindowController(name: "Map 1", mapIndex: maps.count)
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
            DLog.log(.icmp,"got ipv6 packet from \(addr6.string) id \(replyid) sequence \(replysequence)")
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
            DLog.log(.icmp,"received icmp from \(sourceOctet1).\(sourceOctet2).\(sourceOctet3).\(sourceOctet4) id \(id)")
            let sourceIP: UInt32 = UInt32(sourceOctet1) * 256 * 256 * 256 + UInt32(sourceOctet2) * 256 * 256 + UInt32(sourceOctet3) * 256 + UInt32(sourceOctet4)
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.receivedPing4(ip: sourceIP, sequence: sequence, id: id)
            //}
            return
        }, &context)
        socket4Source = CFSocketCreateRunLoopSource(nil, ping4Socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), socket4Source, .commonModes)
        
        emailAlertTimer = Timer.scheduledTimer(timeInterval: Double(Defaults.emailTimerDuration), target: self, selector: #selector(sendAlertEmails), userInfo: nil, repeats: true)
        emailAlertTimer.tolerance = Defaults.emailTimerTolerance
        RunLoop.current.add(emailAlertTimer,forMode: .common)
        
        let calendar = Calendar(identifier: .iso8601)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone.current, era: nil, year: nil, month: nil, day: nil, hour: 8, minute: 8, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        if let dateToFire = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            emailReportTimer = Timer(fireAt: dateToFire, interval: 86400, target: self, selector: #selector(dailyBookkeeping), userInfo: nil, repeats: true)
            RunLoop.current.add(emailReportTimer,forMode: .common)
            DLog.log(.other,"Daily report timer scheduled for \(dateToFire.description)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        _ = saveAllConfig(self)
    }
/*
     // rejected due to user interface guidelines.  Saving to resubmit later. 2/14/19
     
     func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Do you really want to quit Network Mom?"
        alert.informativeText = "Shutting down Network Mom will stop all monitoring, alerts, and data collection.  Data will be automatically saved."
        alert.addButton(withTitle: "Cancel Exit")
        alert.addButton(withTitle: "Confirm Exit")
        let response = alert.runModal()
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            DLog.log(.userInterface,"Terminate alert: first button return, cancelling")
            return NSApplication.TerminateReply.terminateCancel
        case NSApplication.ModalResponse.alertSecondButtonReturn:
            DLog.log(.userInterface,"Terminate alert: second button return, terminating")
            return NSApplication.TerminateReply.terminateNow
        default:
            DLog.log(.userInterface,"ERROR: Terminate Alert unexpected response \(response)")
            return NSApplication.TerminateReply.terminateLater
        }
    }
*/
    private func audioAlertPlay() {
        if let currentSound = currentSound {
            currentSound.play()
        } else {
            NSSound.beep()
        }
    }
    public func audioAlert(override: Bool = false) {
        DLog.log(.monitor, "audioAlert requested")
        // override = true means we generate an audio alert regardless of preferences, used for testing
        if override {
            audioAlertPlay()
            return
        }
        if audioAlertFrequency == Int.max {
            return
        }
        let currentDate = Date()
        if let lastAudioAlert = lastAudioAlert {
            if currentDate.timeIntervalSince(lastAudioAlert) < Double(audioAlertFrequency) {
                DLog.log(.monitor, "supressing audio alert due to short duration")
                return
            }
        }
        lastAudioAlert = currentDate
        DLog.log(.monitor, "generating audio alert")
        audioAlertPlay()
    }
    public func setAudioSound(newSound: NSSound?, newTitle: String?) {
        self.currentSound = newSound  //could be nil which means use system beep
        if let newTitle = newTitle {
            self.audioName = newTitle
        } else {
            self.audioName = Constants.systemBeep
        }
    }
    
    @IBAction func configureEmailServer(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"Configure Email Server selected")
        emailServerController = EmailServerController()
        emailServerController.showWindow(self)
    }
    
    @IBAction func configureEmailRecipient(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"Configure Email Recipient selected")
        let addEmailRecipientController = AddEmailRecipientController()
        addEmailRecipientControllers.append(addEmailRecipientController)
        addEmailRecipientController.showWindow(self)
    }
    func createUniqueMapName() -> String {
        var candidateName: String
        var count = maps.count
        repeat {
            count = count + 1
            candidateName = "Map \(count)"
        } while !mapNameIsUnique(name: candidateName)
        return candidateName
    }

    @IBAction func deleteEmailRecipient(_ sender: NSMenuItem) {
        let deleteEmailRecipientController = DeleteEmailRecipientController()
        deleteEmailRecipientControllers.append(deleteEmailRecipientController)
        deleteEmailRecipientController.showWindow(self)
    }
    
    public func deleteEmail(addressToDelete: String) {
        for (index,email) in emails.enumerated().reversed() {
            if email.email == addressToDelete {
                DLog.log(.dataIntegrity, "deleting email \(email.email) at emails index \(index)" )
                emails.remove(at: index)
            }
        }
        for map in maps {
            map.deleteEmail(addressToDelete: addressToDelete)
        }
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
    
    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc func dailyBookkeeping() {
        emailReports()
    }
    @IBAction func emailDailyReports(_ sender: NSMenuItem) {
        emailReports(reportType: .daily)
    }
    @IBAction func emailWeeklyReports(_ sender: NSMenuItem) {
        emailReports(reportType: .weekly)
    }
    @IBAction func emailMonthlyReports(_ sender: NSMenuItem) {
        emailReports(reportType: .monthly)
    }
    
    func emailReports(reportType: ReportType) {
        for map in maps {
            map.emailReport(reportType: reportType)
        }
    }
    @objc func emailReports() {
        let now = Date()
        emailReports(reportType: .daily)
        let weekday = Calendar.current.component(.weekday, from: now)
        if weekday == 2 {    //2 is a Monday
            emailReports(reportType: .weekly)
        }
        let monthday = Calendar.current.component(.day, from: now)
        if monthday == 2 { // 2nd of the month
            emailReports(reportType: .monthly)
        }
    }
    @IBAction func emailNotificationConfigurationReport(_ sender: NSMenuItem) {
        let emailNotificationConfigurationReportController = EmailNotificationConfigurationReportController()
        emailNotificationConfigurationReportControllers.append(emailNotificationConfigurationReportController)
        emailNotificationConfigurationReportController.showWindow(self)
    }

    func fixMapIndex() {
        DLog.log(.dataIntegrity,"fixing ids in each map")
        for (index,map) in maps.enumerated() {
            map.mapIndex = index
        }
    }

    func loadEmailPassword() {
        if let emailServerHostname = userDefaults.string(forKey: Constants.emailServerHostname), let emailServerUsername = userDefaults.string(forKey: Constants.emailServerUsername) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrServer as String: emailServerHostname,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
                kSecAttrProtocol as String: Constants.networkmom]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            let statusString: String
            if let cfStatusString = SecCopyErrorMessageString(status, nil) {
                statusString = String(cfStatusString)
            } else {
                statusString = status.description
            }
            guard status == errSecSuccess else {
                DLog.log(.dataIntegrity,"Mail account keychain not found at startup, status \(statusString)")
                DLog.log(.mail,"Mail account keychain not found at startup, status \(statusString)")
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
    
    @IBAction func newMap(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"New Map Selected")
        let newName = createUniqueMapName()
        let newmap = MapWindowController(name: newName, mapIndex: maps.count)
        maps.append(newmap)
        maps.last?.showWindow(self)
    }

    func showSaveAlert(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Exporting Configuration to \(url) Failed"
        alert.informativeText = "Check your disk space and access permissions"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @IBAction func manageEmailNotifications(_ sender: NSMenuItem) {
        let manageEmailNotificationsController = ManageEmailNotificationsController()
        manageEmailNotificationsControllers.append(manageEmailNotificationsController)
        manageEmailNotificationsController.showWindow(self)
    }
    func mapNameIsUnique(name: String) -> Bool {
        for map in maps {
            if map.name == name {
                return false
            }
        }
        return true
    }
    func makeMapNamesUnique() {
        var changed = false
        repeat {
            changed = false
            for (index,map) in maps.enumerated() {
                for loop in 0 ..< index {
                    if map.name == maps[loop].name {
                        DLog.log(.dataIntegrity, "Changed \(map.name) to \(map.name) copy")
                        map.name = map.name + " copy"
                        changed = true
                    }
                }
            }
        } while changed
    }

    public func pendNotification(emailAddress: String, notification: EmailNotification) {
        for email in emails {
            if email.email == emailAddress {
                email.pendingNotifications.append(notification)
            }
        }
    }
    @IBAction func preferencesMenuItem(_ sender: NSMenuItem) {
        if preferencesController == nil {
            preferencesController = PreferencesController()
        }
        preferencesController?.showWindow(self)
    }
    
    @IBAction func restoreAllConfig(_ sender: Any) {
        DLog.log(.dataIntegrity,"restoring all config")
        loadEmailPassword()
        
        
        //attempting to load emails from core data
        DLog.log(.dataIntegrity,"Attempting to read email list from Core Data")
        let request = NSFetchRequest<CoreEmailAddress>(entityName: Constants.CoreEmailAddress)
        let sortDescriptor = NSSortDescriptor(key: "email",ascending: true)
        request.sortDescriptors = [sortDescriptor]
        do {
            let coreEmails = try managedContext.fetch(request)
            
            DLog.log(.dataIntegrity,"read \(coreEmails.count) email addresses from core data")
            for coreEmail in coreEmails {
                DLog.log(.dataIntegrity,"importing email \(String(describing: coreEmail.email))")
                let emailAddress = EmailAddress(coreEmailAddress: coreEmail, context: managedContext)
                emails.append(emailAddress)
                
            }
        } catch {
            DLog.log(.dataIntegrity,"Failed to read email addresses from Core data error: \(error)")
        }

        let mapRequest = NSFetchRequest<CoreMap>(entityName: Constants.CoreMap)
        do {
            let coreMaps = try managedContext.fetch(mapRequest)
            DLog.log(.dataIntegrity,"read \(coreMaps.count) maps from core data")
            for (index,coreMap) in coreMaps.enumerated() {
                DLog.log(.dataIntegrity,"importing map \(String(describing: coreMap.name))")
                let newMap = MapWindowController(mapIndex: index, coreMap: coreMap)
                maps.append(newMap)
            }
        } catch {
            DLog.log(.dataIntegrity,"Failed to read maps from Core data error: \(error)")
        }
        fixMapIndex()
    }
    @IBAction func reviewNetworkMom(_ sender: NSMenuItem) {
        // Note: Replace the XXXXXXXXXX below with the App Store ID for your app
        //       You can find the App Store ID in your app's product URL
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1451571383?action=write-review")
            else {
                DLog.log(.userInterface,"Invalid URL in reviewNetworkMom")
                return
            }
        do {
            try NSWorkspace.shared.open(writeReviewURL, options: [], configuration: [:])
        } catch {
            DLog.log(.userInterface,"Unable to open write review URL error \(error.localizedDescription)")
        }
    }
    
    @IBAction func saveConfigMenu(_ sender: Any) {
        let _ : Bool = saveAllConfig(sender)
    }
    func saveAllConfig(_ sender: Any) -> Bool {
        DLog.log(.dataIntegrity,"saving all config")
        let startSaveTime = Date()
        for map in maps {
            map.writeCoreData()
        }
        let success = coreDataStack.saveContext()
        let timeElapsed = Date().timeIntervalSince(startSaveTime)
        self.lastSaveTimeElapsed = timeElapsed
        if success {
            DLog.log(.dataIntegrity,"Core Data Saved in \(timeElapsed) seconds")
        } else {
            DLog.log(.dataIntegrity,"ALERT: Core Data save failed in \(timeElapsed) seconds")
        }
        return true
    }
    
    @IBAction func showLogMenu(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"show log menu")
        let showLogController = ShowLogController()
        showLogControllers.append(showLogController)
        showLogController.showWindow(self)
    }
    
    @IBAction func showStatisticsMenu(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"show statistics menu")
        let showStatisticsController = ShowStatisticsController()
        showStatisticsControllers.append(showStatisticsController)
        showStatisticsController.managedContext = managedContext
        showStatisticsController.showWindow(self)
    }
    
    

    @objc func sendAlertEmails() {
        DLog.log(.mail,"Checking for email alerts to send")
        for email in emails {
            email.emailAlert()
        }
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

