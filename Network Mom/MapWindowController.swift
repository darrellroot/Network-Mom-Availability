//
//  MapWindowController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/2/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa
import Network
import DLog
import SwiftSMTP

class MapWindowController: NSWindowController {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var coreMap: CoreMap?
    
    //var windowFrame: NSRect? // used during decoding
    var availability: RRDGauge
    var mapIndex: Int! // index in AppDelegate maps array
    let minBorder: CGFloat = 20.0  // minimum margin when shrinking window
    var monitors: [Monitor] = []
    var monitorViews: [DragMonitorView] = []
    var ipv4monitors: [MonitorIPv4] = []  // just used during encoding
    var ipv6monitors: [MonitorIPv6] = []  // just used during encoding
    var emailAlerts: [String] = [] //each string is an email address inside the appDelegate.emails
    var emailReports: [String] = [] //each string is an email address inside the appDelegate.emails
    var editMapController: EditMapController?
    
    @IBOutlet weak var mainView: NSView!

    var name: String {
        didSet {
            window?.title = name
            DLog.log(.userInterface,"Window title updated \(name)")
        }
    }
    var ipv4Monitor: AddIPv4MonitorController!
    var ipv6Monitor: AddIPv6MonitorController!
    var importMonitorListControllers: [ImportMonitorListController] = []
    var mapAvailabilityReportControllers: [MapAvailabilityReportController] = []

    var addIPv4MonitorsControllers: [AddIPv4MonitorsController] = []
    var addIPv6MonitorsControllers: [AddIPv6MonitorsController] = []

    var pingSweepIteration = 0
    var numberSweeps: Int
    var pingTimer: Timer!

    var lastMonitorAddTime = Date()
    var nextMonitorAddX = 40.0
    var nextMonitorAddY = 40.0
    
    @IBAction func AddIPv4MonitorMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv4monitor clicked")
        ipv4Monitor = AddIPv4MonitorController()
        ipv4Monitor.delegate = self as AddMonitorDelegate
        //ipv4Monitor.showWindow(self)
        window?.beginSheet(ipv4Monitor.window!, completionHandler: {
            response in
        } )
    }
    
    @IBAction func AddIPv4MonitorsMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv4monitors clicked")
        let addIPv4MonitorsController = AddIPv4MonitorsController()
        addIPv4MonitorsController.delegate = self
        addIPv4MonitorsController.showWindow(self)
        addIPv4MonitorsControllers.append(addIPv4MonitorsController)
    }
    
    
    @IBAction func AddIPv6MonitorMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv6monitor clicked")
        ipv6Monitor = AddIPv6MonitorController()
        ipv6Monitor.delegate = self
        window?.beginSheet(ipv6Monitor.window!, completionHandler: {
            response in
        } )
    }
    
    @IBAction func AddIPv6MonitorsMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv6monitors clicked")
        let addIPv6MonitorsController = AddIPv6MonitorsController()
        addIPv6MonitorsController.delegate = self
        addIPv6MonitorsController.showWindow(self)
        addIPv6MonitorsControllers.append(addIPv6MonitorsController)
    }

    @IBAction func arrangeMonitors(_ sender: NSMenuItem) {
        let columns = monitors.count.squareRoot()
        DLog.log(.userInterface,"arrangeMonitors: monitors.count:\(monitors.count) columns: \(columns)")
        var lastXposition = minBorder
        var lastYposition = minBorder
        var currentColumn = 1
        for monitorView in monitorViews.sorted(by: { ($0.monitor?.hostname ?? "") < ($1.monitor?.hostname ?? "") }) {
            monitorView.frame = NSRect(x: lastXposition, y: lastYposition, width: monitorView.frame.width, height: monitorView.frame.height)
            monitorView.updateFrame()
            if currentColumn >= columns {
                // start next row
                lastXposition = minBorder
                lastYposition = lastYposition + monitorView.frame.height + minBorder
                currentColumn = 1
            } else {
                lastXposition = lastXposition + minBorder + monitorView.frame.width
                currentColumn = currentColumn + 1
            }
        }
        resizeWindow()
    }
    
    func showSaveAlert(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Exporting Configuration to \(url) Failed"
        alert.informativeText = "Check your disk space and access permissions"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @IBAction func editMap(_ sender: NSMenuItem) {
        if editMapController != nil {
            editMapController?.showWindow(self)
        } else {
            editMapController = EditMapController()
            editMapController?.mapDelegate = self
            editMapController?.showWindow(self)
        }
    }
    @IBAction func exportMapMonitorListAsText(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"exportMapMonitorListAsText selected")
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["txt"]
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    DLog.log(.dataIntegrity,"saving to \(url.debugDescription)")
                    self.exportMapMonitorListAsText(url: url)
                }
            } else {
                DLog.log(.dataIntegrity,"File selection not successful")
            }
        }
    }
    func exportMapMonitorListAsText(url: URL) {
        var exportText = ""
        for monitor in monitors {
            switch monitor.type {
            case .MonitorIPv4:
                if let monitor = monitor as? MonitorIPv4 {
                    let hostname = monitor.hostname ?? ""
                    let comment = monitor.comment ?? ""
                    exportText += "\(monitor.ipv4string),\(hostname),\(comment)\n"
                }
            case .MonitorIPv6:
                if let monitor = monitor as? MonitorIPv6 {
                    let hostname = monitor.hostname ?? ""
                    let comment = monitor.comment ?? ""
                    exportText += "\(monitor.ipv6.debugDescription),\(hostname),\(comment)\n"
                }
            }
        }
        do {
            try exportText.write(to: url, atomically: false, encoding: .utf8)
        }
        catch {
            DLog.log(.dataIntegrity,"Export text failed")
        }
    }
    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    /*func exportMap(url: URL) {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            DLog.log(.dataIntegrity,"error encoding map")
            showSaveAlert(url: url)
        }
    }*/
    @IBAction func deleteMap(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Do you really want to delete this map?"
        alert.informativeText = "All monitors and data for this map will be deleted"
        alert.addButton(withTitle: "Cancel Map Deletion")
        alert.addButton(withTitle: "Confirm Map Deletion")
        alert.beginSheetModal(for: window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
                DLog.log(.userInterface,"first button aborts delete")
            }
            if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                DLog.log(.userInterface,"second button confirms delete")
                self.pingTimer.invalidate()
                self.pingTimer = nil
                self.appDelegate.deleteMap(index: self.mapIndex, name: self.name)
            }
        })
    }
    
    deinit {
        DLog.log(.dataIntegrity,"Deinit MapWindowController \(self.name)")
        if let coreMap = self.coreMap {
            coreMap.managedObjectContext?.delete(coreMap)
        }
    }
    public func deleteEmail(addressToDelete: String) {
        emailAlerts.remove(object: addressToDelete)
        emailReports.remove(object: addressToDelete)
    }
    
    private func deleteSelectedMonitor() -> Bool {
        DLog.log(.dataIntegrity,"entered deleteSelectedMonitor")
        for (viewIndex,monitorView) in monitorViews.enumerated() {
            if monitorView.selected == true {
                if let deletedMonitor = monitorView.monitor {
                    for (monitorIndex,monitor) in monitors.enumerated() {
                        if monitor === deletedMonitor {
                            DLog.log(.dataIntegrity,"removing monitor \(monitor.label) at index \(monitorIndex)")
                            monitors.remove(at: monitorIndex)
                            monitorViews.remove(at: viewIndex)
                            monitorView.removeFromSuperview()
                            return true
                        }
                    }
                }
                DLog.log(.dataIntegrity,"WARNING: monitor at index \(viewIndex) was selected but could not be deleted")
                monitorView.selected = false
            }
        }
        return false
    }
    @IBAction func deleteSelectedMonitors(_ sender: NSMenuItem) {
        DLog.log(.dataIntegrity,"entered deleteSelectedMonitors")
        var didADelete: Bool
        repeat {
            didADelete = deleteSelectedMonitor()
        } while didADelete == true
    }


    func emailReport(reportType: ReportType, license: License?) {
        //let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("report.pdf")
        //let fileShortString = "Documents/report.pdf"
        //let filename = "report.pdf"
        //let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        //let directoryURL = FileManager.default.documentDirectory
        //let filename = directoryURL.absoluteString + "/dailyreport.pdf"
        //let fileURL = directoryURL.appendingPathComponent("dailyreport.pdf")
        //DLog.log(.dataIntegrity,"daily report url \(fileURL)")
        //let printOpts: [NSPrintInfo.AttributeKey: Any] = [NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save, NSPrintInfo.AttributeKey.jobSavingURL: fileURL]
        //let printOpts: [NSPrintInfo.AttributeKey: Any] = [NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save]
        //let printInfo = NSPrintInfo(dictionary: printOpts)

        guard let emailConfiguration = appDelegate.emailConfiguration else {
            DLog.log(.dataIntegrity,"No Email Configuration, unable to email map availability reports")
            return
        }
        guard emailReports.count > 0 else {
            DLog.log(.dataIntegrity,"No Email report recipients, skipping map availability reports")
            return
        }

        let pdfData = NSMutableData()

        DLog.log(.userInterface,"map \(name) emailing \(reportType.rawValue) reports")
        let availabilityReport = AvailabilityReport(reportType: reportType, map: self, license: license)
        let availabilityReportView = availabilityReport.makeView()
        availabilityReportView.translatesAutoresizingMaskIntoConstraints = false
        let html = availabilityReport.makeHTML()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 570, height: 500))
        view.addSubview(availabilityReportView)
        let textFields = [
            "availabilityReportView": availabilityReportView,
            ]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[availabilityReportView]|", options: [], metrics: nil, views: textFields))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[availabilityReportView]|", options: [], metrics: nil, views: textFields))
        //let printOperation = NSPrintOperation.pdfOperation(with: view, inside: view.frame, toPath: fileShortString, printInfo: printInfo)
        let printOperation = NSPrintOperation.pdfOperation(with: view, inside: view.frame, to: pdfData )
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = false
        printOperation.run()

        let emails = appDelegate.emails
        var emailHash: [String: EmailAddress] = [:]
        for email in emails {
            emailHash[email.email] = email
        }
        let smtp = SMTP(hostname: emailConfiguration.server, email: emailConfiguration.username, password: emailConfiguration.password, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
        
        let deviceListURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("deviceList-\(name).txt")
        if reportType == .weekly {
            exportMapMonitorListAsText(url: deviceListURL)
        } else {
            try? FileManager.default.removeItem(at: deviceListURL)
        }
        for recipient in emailReports {
            if let emailRecipient = emailHash[recipient] {
                let sender = Mail.User(name: "Network Mom", email: emailConfiguration.username)
                let recipient = Mail.User(name: emailRecipient.name, email: emailRecipient.email)
                let message = ""
                //let attachment = Attachment(filePath: fileURL.absoluteString)
                //let attachment = Attachment(filePath: "/Users/droot/Library/Containers/net.networkmom.availability/Data/Documents/report.pdf", mime: "application/pdf", name: "report.pdf", inline: false, additionalHeaders: [:], relatedAttachments: [])
                //let attachment = Attachment(data: pdfData as Data, mime: "application/pdf", name: "report.pdf")
                let attachment = Attachment(data: pdfData as Data, mime: "application/pdf", name: "report.pdf", inline: true, additionalHeaders: [:], relatedAttachments: [])
                let htmlAttachment = Attachment(htmlContent: html)
                //let attachment = Attachment(filePath: fileURL.relativeString)
                let filePath = deviceListURL.path
                let mail: Mail
                if reportType == .weekly {
                    let deviceList = Attachment(filePath: filePath, mime: "text/plain", name: "deviceList-\(name).txt", inline: false, additionalHeaders: [:], relatedAttachments: [])
                    mail = Mail(from: sender, to: [recipient], cc: [], bcc: [], subject: "Network Mom Availability \(reportType.rawValue) report for map \(name)", text: message, attachments: [htmlAttachment,attachment,deviceList], additionalHeaders: [:])
                } else {
                    mail = Mail(from: sender, to: [recipient], cc: [], bcc: [], subject: "Network Mom Availability \(reportType.rawValue) report for map \(name)", text: message, attachments: [htmlAttachment,attachment], additionalHeaders: [:])
                }
                //let mail = Mail(from: sender, to: [recipient], cc: [], bcc: [], subject: "test email report", text: message, attachments: [], additionalHeaders: [:])

                smtp.send(mail) { (error) in
                    if let error = error {
                        DLog.log(.mail,"email error \(error)")
                        if let error = error as? SMTPError {
                            DLog.log(.mail,error.description)
                        } else {
                            DLog.log(.mail,error.localizedDescription)
                        }
                    } else {
                        DLog.log(.mail,"alert mail sent successfully")
                    }
                }
            }
        }
    }
    @objc func executePings() {
        
        if monitors.count == 0 {
            return
        }
        if appDelegate.license?.licenseStatus == .expired {
            for monitor in monitors {
                monitor.licenseExpired()
            }
            return
        }
        
        for i in 0..<monitors.count {
            if i % numberSweeps == pingSweepIteration {
                //DLog.log(.other,"Executing i \(i) numberSweeps \(numberSweeps) pingSweepIteration \(pingSweepIteration)")
                if let target = monitors[safe: i] as? MonitorIPv4 {
                    target.sendPing(pingSocket: appDelegate.ping4Socket, id: mapIndex)
                }
                if let target = monitors[safe: i] as? MonitorIPv6 {
                    target.sendPing(pingSocket: appDelegate.ping6Socket, id: mapIndex)
                }
            }
            //DLog.log(.other,"i \(i) numberSweeps \(numberSweeps) pingSweepIteration \(pingSweepIteration)")
            }
        pingSweepIteration += 1
        if pingSweepIteration >= numberSweeps {
            pingSweepIteration = 0
        }
    }
    

    @IBAction func importTextMonitorList(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"Import Text Monitor List selected")
        let importMonitorListController = ImportMonitorListController()
        importMonitorListControllers.append(importMonitorListController)
        importMonitorListController.delegate = self
        importMonitorListController.showWindow(self)
    }

    convenience init(name: String, mapIndex: Int) {
        self.init(window: nil)
        self.name = name
        self.mapIndex = mapIndex
        self.coreMap = CoreMap(context: appDelegate.managedContext)
        writeCoreData()
    }
    
    convenience init(mapIndex: Int, coreMap: CoreMap) {
        self.init(window: nil)
        self.mapIndex = mapIndex
        self.coreMap = coreMap
        readCoreData(coreData: coreMap)
    }
    
    func readCoreData(coreData: CoreMap) {
        self.name = coreData.name ?? "unknown map name"
        self.emailAlerts = coreData.emailAlerts ?? []
        self.emailReports = coreData.emailReports ?? []
        let frame = NSRect(x: Double(coreData.frameX), y: Double(coreData.frameY), width: Double(coreData.frameWidth), height: Double(coreData.frameHeight))
        self.window?.setFrame(frame, display: true)
        
        let fiveMinCoreData = coreData.availabilityFiveMinuteData ?? []
        let fiveMinCoreTime = coreData.availabilityFiveMinuteTimestamp ?? []
        let oneHourCoreData = coreData.availabilityOneHourData ?? []
        let oneHourCoreTime = coreData.availabilityOneHourTimestamp ?? []
        let dayCoreData = coreData.availabilityDayData ?? []
        let dayCoreTime = coreData.availabilityDayTimestamp ?? []
        availability = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, oneHourData: oneHourCoreData, oneHourTime: oneHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        
        for coreMonitorIPv4 in coreData.ipv4monitors ?? [] {
            if let ipv4Monitor = MonitorIPv4(coreData: coreMonitorIPv4) {
                ipv4Monitor.mapDelegate = self
                self.monitors.append(ipv4Monitor as Monitor)
            }
        }
        for coreMonitorIPv6 in coreData.ipv6monitors ?? [] {
            if let ipv6Monitor = MonitorIPv6(coreData: coreMonitorIPv6) {
                ipv6Monitor.mapDelegate = self
                self.monitors.append(ipv6Monitor as Monitor)
            }
        }
        for monitor in monitors {
            if monitor.viewDelegate == nil {
                var newFrame: NSRect
                if let viewFrame = monitor.viewFrame {
                    newFrame = viewFrame
                } else {
                    newFrame = NSRect(x: 50, y: 50, width: 50, height: 30)
                }
                let dragMonitorView = DragMonitorView(frame: newFrame, monitor: monitor)
                dragMonitorView.controllerDelegate = self
                monitorViews.append(dragMonitorView)
                mainView?.addSubview(dragMonitorView)
                monitor.viewDelegate = dragMonitorView
            }
        }
        resizeWindow()
    }

    required init?(coder: NSCoder) {
        numberSweeps = Defaults.pingSweepDuration / Defaults.pingTimerDuration
        guard Defaults.pingSweepDuration % Defaults.pingTimerDuration == 0 else {
            fatalError("pingSweepDuration is not an integer multiple of pingTimerDuration")
        }
        availability = RRDGauge()
        self.name = "Decoded"
        super.init(coder: coder)
    }
    override init(window: NSWindow?) {
        numberSweeps = Defaults.pingSweepDuration / Defaults.pingTimerDuration
        guard Defaults.pingSweepDuration % Defaults.pingTimerDuration == 0 else {
            fatalError("pingSweepDuration is not an integer multiple of pingTimerDuration")
        }
        name = "error"
        availability = RRDGauge()
        super.init(window: window)
        self.shouldCascadeWindows = true
    }
    
    @IBAction func mapAvailabilityReport(_ sender: NSMenuItem) {
        let mapAvailabilityReportController = MapAvailabilityReportController()
        mapAvailabilityReportControllers.append(mapAvailabilityReportController)
        mapAvailabilityReportController.delegate = self
        switch sender.tag {
        case 1:
            mapAvailabilityReportController.reportType = .daily
        case 2:
            mapAvailabilityReportController.reportType = .weekly
        case 3:
            mapAvailabilityReportController.reportType = .monthly
        default:
            DLog.log(.userInterface,"Error in map availability report menu item: no tag detected")
            mapAvailabilityReportController.reportType = .daily
        }
        mapAvailabilityReportController.showWindow(self)
    }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 1 {
            deselectAll()
        }
    }

    func receivedPing4(ip: UInt32, sequence: UInt16, id: UInt16) {
        //print("map \(String(describing: name)) receivedPing4 ip \(ip) sequence \(sequence) id \(id)")
        for monitor in monitors {
            if let monitor = monitor as? MonitorIPv4 {
                if ip == monitor.ipv4 {
                    monitor.receivedPing(ip: ip, sequence: sequence, id: id)
                }
            }
        }
    }

    func receivedPing6(ipv6: IPv6Address, sequence: UInt16, id: UInt16) {
        //print("receivedPing6 ip \(ipv6.debugDescription) sequence \(sequence) id \(id)")
        for monitor in monitors {
            if let monitor = monitor as? MonitorIPv6 {
                if ipv6 == monitor.ipv6 {
                    monitor.receivedPing(receivedip: ipv6, sequence: sequence, id: id)
                }
            }
        }
    }
    
    func writeCoreData() {
        DLog.log(.dataIntegrity,"Map \(name) writing core data")
        if coreMap == nil {
            DLog.log(.dataIntegrity,"Initializing coreMap core data structure in MapWindowController \(name)")
            self.coreMap = CoreMap(context: appDelegate.managedContext)
        }
        if let coreData = self.coreMap {
            coreData.emailAlerts = emailAlerts
            coreData.emailReports = emailReports
            coreData.frameHeight = Float(window?.frame.height ?? 200.0)
            coreData.frameWidth = Float(window?.frame.width ?? 200.0)
            coreData.frameX = Float(window?.frame.minX ?? 40.0)
            coreData.frameY = Float(window?.frame.minY ?? 40.0)
            coreData.name = name
            
            
            for dataType in MonitorDataType.allCases {
                let data = availability.getData(dataType: dataType)
                var timestamps: [Int] = []
                var values: [Double] = []
                for dataPoint in data {
                    if let value = dataPoint.value {
                        timestamps.append(dataPoint.timestamp)
                        values.append(value)
                    }
                }
                switch dataType {
                case .FiveMinute:
                    coreData.availabilityFiveMinuteTimestamp = timestamps
                    coreData.availabilityFiveMinuteData = values
                case .OneHour:
                    coreData.availabilityOneHourTimestamp = timestamps
                    coreData.availabilityOneHourData = values
                case .OneDay:
                    coreData.availabilityDayTimestamp = timestamps
                    coreData.availabilityDayData = values
                }
                DLog.log(.dataIntegrity, "Map IPv6 \(name) availability wrote dataType \(dataType) \(values.count) entries")
            }

            
            for monitor in monitors {
                monitor.writeCoreData()
            }
        } else {
            DLog.log(.dataIntegrity,"Error: failed to initialize core data structure in MapWindowController \(name)")
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        /*if let windowFrame = windowFrame {
            DLog.log(.userInterface,"window frame \(windowFrame)")
            window?.setFrame(windowFrame,display: true)
        }*/
        //resizeWindow()
        let name2 = name
        name = name2 // trigger didset
        
        pingTimer = Timer.scheduledTimer(timeInterval: Double(Defaults.pingTimerDuration), target: self, selector: #selector(executePings), userInfo: nil, repeats: true)
        pingTimer.tolerance = 0.3
        RunLoop.current.add(pingTimer,forMode: .common)

    }
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("MapWindowController")
    }
}

extension MapWindowController: AddMonitorDelegate {
    func alreadyMonitored(ipv4String: String) -> Bool {
        for monitor in monitors {
            if let monitor = monitor as? MonitorIPv4 {
                if ipv4String == monitor.ipv4string {
                    return true
                }
            }
        }
        return false
    }
    func alreadyMonitored(ipv6: IPv6Address) -> Bool {
        for monitor in monitors {
            if let monitor = monitor as? MonitorIPv6 {
                if ipv6 == monitor.ipv6 {
                    return true
                }
            }
        }
        return false
    }

    func updateNextPosition() {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastMonitorAddTime) > 2.0 {
            nextMonitorAddX = Double(2 * minBorder)
            nextMonitorAddY = Double(2 * minBorder)
        } else {
            nextMonitorAddX = nextMonitorAddX + Double(minBorder)
            nextMonitorAddY = nextMonitorAddY + Double(minBorder)
        }
        lastMonitorAddTime = currentTime
    }
    func addIPv4Monitor(monitor: MonitorIPv4) {
        updateNextPosition()
        monitors.append(monitor as Monitor)
        monitor.mapDelegate = self
        monitor.coreMonitorIPv4?.coreMap = self.coreMap
        let dragMonitorView = DragMonitorView(frame: NSRect(x: nextMonitorAddX, y: nextMonitorAddY, width: 50, height: 30), monitor: monitor)
        dragMonitorView.controllerDelegate = self
        monitorViews.append(dragMonitorView)
        mainView?.addSubview(dragMonitorView)
    }
    func addIPv6Monitor(monitor: MonitorIPv6) {
        updateNextPosition()
        monitors.append(monitor as Monitor)
        monitor.mapDelegate = self
        monitor.coreMonitorIPv6?.coreMap = self.coreMap
        let dragMonitorView = DragMonitorView(frame: NSRect(x: nextMonitorAddX, y: nextMonitorAddY, width: 50, height: 30), monitor: monitor)
        dragMonitorView.controllerDelegate = self
        monitorViews.append(dragMonitorView)
        mainView?.addSubview(dragMonitorView)
    }
}
extension MapWindowController: ControllerDelegate {
    func deselectAll() {
        for view in monitorViews {
            view.selected = false
        }
    }
}
extension MapWindowController: NSWindowDelegate {
    func windowDidEndLiveResize(_ notification: Notification) {
        resizeWindow()
    }
    func resizeWindow() {
        if let frame = window?.frame, let content = window?.contentRect(forFrameRect: frame) {
            var maxX: CGFloat = content.width
            var maxY: CGFloat = content.height
            for view in monitorViews {
                let frameMaxX = view.frame.maxX + minBorder
                let frameMaxY = view.frame.maxY + minBorder
                if frameMaxX > maxX {
                    maxX = frameMaxX
                }
                if frameMaxY > maxY {
                    maxY = frameMaxY
                }
            }
            mainView?.setFrameSize(NSSize(width: maxX, height: maxY))
        }
    }
}
