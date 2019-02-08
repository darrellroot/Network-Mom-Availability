//
//  MapAvailabilityReportController.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/25/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog
import WebKit

class MapAvailabilityReportController: NSWindowController {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    weak var delegate: MapWindowController?
    var pdfData = NSMutableData()
    var reportType: ReportType = .daily // daily by default
    
    @IBOutlet weak var webView: WKWebView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("MapAvailabilityReportController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        let availabilityReport = AvailabilityReport(reportType: reportType, map: delegate, license: appDelegate.license)
        let html = availabilityReport.makeHTML()
        webView.loadHTMLString(html, baseURL: nil)
        window?.title = "\(delegate?.name ?? "unknown") \(reportType.rawValue) availability report"
    }
    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface,"Removing map availability report controller")
        delegate?.mapAvailabilityReportControllers.remove(object: self)
    }
    /*@IBAction func printReport(_ sender: NSMenuItem) {
        DLog.log(.userInterface, "mapavailabilityreportcontroller print")
        let availabilityReport = AvailabilityReport(reportType: .daily, map: delegate)
        let availabilityReportView = availabilityReport.makeView()
        availabilityReportView.translatesAutoresizingMaskIntoConstraints = false
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let printOpts: [NSPrintInfo.AttributeKey: Any] = [NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save, NSPrintInfo.AttributeKey.jobSavingURL: directoryURL]
        let printInfo = NSPrintInfo(dictionary: printOpts)
        printInfo.horizontalPagination = NSPrintInfo.PaginationMode.automatic
        printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
        printInfo.topMargin = 20.0
        printInfo.leftMargin = 20.0
        printInfo.rightMargin = 20.0
        printInfo.bottomMargin = 20.0

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 570, height: 740))
        view.addSubview(availabilityReportView)
        let textFields = [
            "availabilityReportView2": availabilityReportView,
            ]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[availabilityReportView2]|", options: [], metrics: nil, views: textFields))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[availabilityReportView2]|", options: [], metrics: nil, views: textFields))
        let printOperation = NSPrintOperation.pdfOperation(with: view, inside: view.frame, to: pdfData)
        //let printOperation = NSPrintOperation(view: view, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = false
        printOperation.run()
        print("dfjlkdj")
    }*/
}
