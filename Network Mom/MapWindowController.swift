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
    //var mapAvailabilityReportController: MapAvailabilityReportController!
    var addIPv4MonitorsControllers: [AddIPv4MonitorsController] = []
    var addIPv6MonitorsControllers: [AddIPv6MonitorsController] = []

    var pingSweepIteration = 0
    var numberSweeps: Int
    var pingTimer: Timer!

    
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

    func showSaveAlert(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Exporting Configuration to \(url) Failed"
        alert.informativeText = "Check your disk space and access permissions"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /*@IBAction func exportMap(_ sender: NSMenuItem) {
        DLog.log(.dataIntegrity,"attempting to export map")
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["mom1"]
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    DLog.log(.dataIntegrity,"saving to \(url.debugDescription)")
                    self.exportMap(url: url)
                }
            } else {
                DLog.log(.dataIntegrity,"File selection not successful")
            }
        }
    }*/
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

    @objc func executePings() {
        if monitors.count == 0 {
            return
        }
        for i in 0..<monitors.count {
            if i % numberSweeps == pingSweepIteration {
                if let target = monitors[i] as? MonitorIPv4 {
                    target.sendPing(pingSocket: appDelegate.ping4Socket, id: mapIndex)
                }
                if let target = monitors[i] as? MonitorIPv6 {
                    target.sendPing(pingSocket: appDelegate.ping6Socket, id: mapIndex)
                }
            }
            pingSweepIteration += 1
            if pingSweepIteration >= numberSweeps {
                pingSweepIteration = 0
            }
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
        let thirtyMinCoreData = coreData.availabilityThirtyMinuteData ?? []
        let thirtyMinCoreTime = coreData.availabilityThirtyMinuteTimestamp ?? []
        let twoHourCoreData = coreData.availabilityTwoHourData ?? []
        let twoHourCoreTime = coreData.availabilityTwoHourTimestamp ?? []
        let dayCoreData = coreData.availabilityDayData ?? []
        let dayCoreTime = coreData.availabilityDayTimestamp ?? []
        availability = RRDGauge(fiveMinData: fiveMinCoreData, fiveMinTime: fiveMinCoreTime, thirtyMinData: thirtyMinCoreData, thirtyMinTime: thirtyMinCoreTime, twoHourData: twoHourCoreData, twoHourTime: twoHourCoreTime, dayData: dayCoreData, dayTime: dayCoreTime)
        
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
                case .ThirtyMinute:
                    coreData.availabilityThirtyMinuteTimestamp = timestamps
                    coreData.availabilityThirtyMinuteData = values
                case .TwoHour:
                    coreData.availabilityTwoHourTimestamp = timestamps
                    coreData.availabilityTwoHourData = values
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

    
    func addIPv4Monitor(monitor: MonitorIPv4) {
        monitors.append(monitor as Monitor)
        monitor.mapDelegate = self
        monitor.coreMonitorIPv4?.coreMap = self.coreMap
        let dragMonitorView = DragMonitorView(frame: NSRect(x: 50, y: 50, width: 50, height: 30), monitor: monitor)
        dragMonitorView.controllerDelegate = self
        monitorViews.append(dragMonitorView)
        mainView?.addSubview(dragMonitorView)
    }
    func addIPv6Monitor(monitor: MonitorIPv6) {
        monitors.append(monitor as Monitor)
        monitor.mapDelegate = self
        monitor.coreMonitorIPv6?.coreMap = self.coreMap
        let dragMonitorView = DragMonitorView(frame: NSRect(x: 50, y: 50, width: 50, height: 30), monitor: monitor)
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
