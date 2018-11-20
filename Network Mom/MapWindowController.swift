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

class MapWindowController: NSWindowController, Codable {

    enum CodingKeys: String, CodingKey {
        case availability
        case ipv4monitors
        case ipv6monitors
        case name
        case frame
    }

    var windowFrame: NSRect? // used during decoding
    var availability: RRDGauge
    var mapIndex: Int! // index in AppDelegate maps array
    let minBorder: CGFloat = 20.0  // minimum margin when shrinking window
    var monitors: [Monitor] = []
    var monitorViews: [DragMonitorView] = []
    var ipv4monitors: [MonitorIPv4] = []  // just used during encoding
    var ipv6monitors: [MonitorIPv6] = []  // just used during encoding
    
    @IBOutlet weak var mainView: NSView!

    var name: String {
        didSet {
            window?.title = name
            DLog.log(.userInterface,"Window title updated \(name)")
        }
    }
    var ipv4Monitor: AddIPv4MonitorController!
    var ipv6Monitor: AddIPv6MonitorController!
    var mapAvailabilityReportController: MapAvailabilityReportController!
    
    var pingSweepIteration = 0
    var pingTimerDuration: Int = 1
    var pingSweepDuration: Int = 5 //must be an integer multiple of pingTimerDuration
    var numberSweeps: Int
    var pingTimer: Timer!

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        availability = try container.decode(RRDGauge.self, forKey: .availability)
        name = try container.decode(String.self, forKey: .name)
        ipv4monitors = try container.decode([MonitorIPv4].self, forKey: .ipv4monitors)
        ipv6monitors = try container.decode([MonitorIPv6].self, forKey: .ipv6monitors)
        windowFrame = try? container.decode(NSRect.self, forKey: .frame)
        monitors = ipv4monitors as [Monitor] + ipv6monitors as [Monitor]
        ipv4monitors = []  // temp variables just used during decoding
        ipv6monitors = []
        numberSweeps = pingSweepDuration / pingTimerDuration
        guard pingSweepDuration % pingTimerDuration == 0 else {
            fatalError("pingSweepDuration is not an integer multiple of pingTimerDuration")
        }
        super.init(window: nil)
        for monitor in ipv4monitors {
            monitor.mapDelegate = self
        }
        for monitor in ipv6monitors {
            monitor.mapDelegate = self
        }
        //monitors = try container.decode([Monitor].self, forKey: .monitors)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.availability, forKey: .availability)
        try container.encode(self.name, forKey: .name)
//        try container.encode(self.monitors, forKey: .monitors)
        for monitor in monitors {
            if let monitor = monitor as? MonitorIPv4 {
                ipv4monitors.append(monitor)
            }
            if let monitor = monitor as? MonitorIPv6 {
                ipv6monitors.append(monitor)
            }
        }
        try container.encode(ipv4monitors, forKey: .ipv4monitors)
        try container.encode(ipv6monitors, forKey: .ipv6monitors)
        ipv4monitors = []
        ipv6monitors = []
        if let frame = window?.frame {
            try container.encode(frame, forKey: .frame)
        }
    }
    
    @IBAction func AddIPv4MonitorMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv4monitor clicked")
        ipv4Monitor = AddIPv4MonitorController()
        ipv4Monitor.delegate = self as AddMonitorDelegate
        //ipv4Monitor.showWindow(self)
        window?.beginSheet(ipv4Monitor.window!, completionHandler: {
            response in
        } )
    }
    
    @IBAction func AddIPv6MonitorMenuItem(_ sender: NSMenuItem) {
        DLog.log(.userInterface,"addIPv6monitor clicked")
        ipv6Monitor = AddIPv6MonitorController()
        ipv6Monitor.delegate = self
        window?.beginSheet(ipv6Monitor.window!, completionHandler: {
            response in
        } )
    }
    
    func showSaveAlert(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = "Exporting Configuration to \(url) Failed"
        alert.informativeText = "Check your disk space and access permissions"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @IBAction func exportMap(_ sender: NSMenuItem) {
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
    }
    
    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func exportMap(url: URL) {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            DLog.log(.dataIntegrity,"error encoding map")
            showSaveAlert(url: url)
        }
    }
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
                self.appDelegate.deleteMap(index: self.mapIndex, name: self.name)
            }
        })
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

    convenience init(name: String, mapIndex: Int) {
        self.init(window: nil)
        self.name = name
        self.mapIndex = mapIndex
    }
    
    required init?(coder: NSCoder) {
        numberSweeps = pingSweepDuration / pingTimerDuration
        guard pingSweepDuration % pingTimerDuration == 0 else {
            fatalError("pingSweepDuration is not an integer multiple of pingTimerDuration")
        }
        availability = RRDGauge()
        self.name = "Decoded"
        super.init(coder: coder)
    }
    override init(window: NSWindow?) {
        numberSweeps = pingSweepDuration / pingTimerDuration
        guard pingSweepDuration % pingTimerDuration == 0 else {
            fatalError("pingSweepDuration is not an integer multiple of pingTimerDuration")
        }
        name = "error"
        availability = RRDGauge()
        super.init(window: window)
        self.shouldCascadeWindows = true
    }
    
    @IBAction func mapAvailabilityReport(_ sender: NSMenuItem) {
        mapAvailabilityReportController = MapAvailabilityReportController()
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
    override func windowDidLoad() {
        super.windowDidLoad()
        if let windowFrame = windowFrame {
            DLog.log(.userInterface,"window frame \(windowFrame)")
            window?.setFrame(windowFrame,display: true)
        }
        resizeWindow()
        let name2 = name
        name = name2 // trigger didset
        
        for monitor in monitors {
            if monitor.viewDelegate == nil {
                // this means we just imported the map via codable
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
        pingTimer = Timer.scheduledTimer(timeInterval: Double(pingTimerDuration), target: self, selector: #selector(executePings), userInfo: nil, repeats: true)
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
        let dragMonitorView = DragMonitorView(frame: NSRect(x: 50, y: 50, width: 50, height: 30), monitor: monitor)
        dragMonitorView.controllerDelegate = self
        monitorViews.append(dragMonitorView)
        mainView?.addSubview(dragMonitorView)
    }
    func addIPv6Monitor(monitor: MonitorIPv6) {
        monitors.append(monitor as Monitor)
        monitor.mapDelegate = self
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
/*
extension MapWindowController: NSOpenSavePanelDelegate {
    func panel(_ sender: Any, validate: URL) {
        print("url to validate \(validate)")
    }
}
 */
