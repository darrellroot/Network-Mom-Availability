//
//  EmailNotificationConfigurationReportController.swift
//  Network Mom
//
//  Created by Darrell Root on 12/3/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class EmailNotificationConfigurationReportController: NSWindowController, NSWindowDelegate {

    private struct emailDataLine {
        let map: String
        var name: String
        let email: String
        var alerts: Bool
        var reports: Bool
    }
    
    private var emailData: [emailDataLine] = []
    private var emailDataSorted: [emailDataLine] = []
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var tableViewOutlet: NSTableView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EmailNotificationConfigurationReportController")
    }

    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface, "EmailNotificationConfigurationReport window closing")
        appDelegate.emailNotificationConfigurationReportControllers.remove(object: self)
    }
    override func windowDidLoad() {
        super.windowDidLoad()

        var emailHash: [String:String] = [:]
        
        for map in appDelegate.maps {
            var thisMapData: [emailDataLine] = []
            for email in appDelegate.emails {
                emailHash[email.email] = email.name
            }
            for email in map.emailAlerts {
                let name = emailHash[email] ?? ""
                let newLine = emailDataLine(map: map.name, name: name, email: email, alerts: true, reports: false)
                
                thisMapData.append(newLine)
            }
            for email in map.emailReports {
                if let index =  thisMapData.firstIndex(where: { $0.email == email }) {
                    thisMapData[index].reports = true
                } else {
                    let name = emailHash[email] ?? ""
                    let newLine = emailDataLine(map: map.name, name: name, email: email, alerts: false, reports: true)
                    thisMapData.append(newLine)
                }
            }
            emailData += thisMapData
        }
        emailDataSorted = emailData
        sortData(by: .Email, ascending: true)
        sortData(by: .Map, ascending: true)
/*       case Map = "Map"
        case Email = "Email"
        case Name = "Name"
        case Alerts = "Alerts"
        case Reports = "Reports"*/

        let descriptorMap = NSSortDescriptor(key: CellIdentifier.Map.rawValue, ascending: true)
        let descriptorEmail = NSSortDescriptor(key: CellIdentifier.Email.rawValue, ascending: true)
        let descriptorName = NSSortDescriptor(key: CellIdentifier.Name.rawValue, ascending: true)
        let descriptorAlerts = NSSortDescriptor(key: CellIdentifier.Alerts.rawValue, ascending: true)
        let descriptorReports = NSSortDescriptor(key: CellIdentifier.Reports.rawValue, ascending: true)
        tableViewOutlet.tableColumns[0].sortDescriptorPrototype = descriptorMap
        tableViewOutlet.tableColumns[1].sortDescriptorPrototype = descriptorEmail
        tableViewOutlet.tableColumns[2].sortDescriptorPrototype = descriptorName
        tableViewOutlet.tableColumns[3].sortDescriptorPrototype = descriptorAlerts
        tableViewOutlet.tableColumns[4].sortDescriptorPrototype = descriptorReports

        tableViewOutlet.delegate = self
        tableViewOutlet.dataSource = self
        tableViewOutlet.reloadData()
    }
}

extension EmailNotificationConfigurationReportController: NSTableViewDataSource, NSTableViewDelegate {
    
    fileprivate enum CellIdentifier: String {
        case Map = "Map"
        case Email = "Email"
        case Name = "Name"
        case Alerts = "Alerts"
        case Reports = "Reports"
    }
    
    fileprivate func sortData(by cellIdentifier: CellIdentifier, ascending: Bool) {
        switch cellIdentifier {
        case CellIdentifier.Map:
            emailDataSorted = emailDataSorted.sorted(by: {$0.map < $1.map})
        case CellIdentifier.Email:
            emailDataSorted = emailDataSorted.sorted(by: {$0.email < $1.email})
        case CellIdentifier.Name:
            emailDataSorted = emailDataSorted.sorted(by: {$0.name < $1.name})
        case CellIdentifier.Alerts:
            emailDataSorted = emailDataSorted.sorted(by: {$0.alerts && !$1.alerts})
        case CellIdentifier.Reports:
            emailDataSorted = emailDataSorted.sorted(by: {$0.reports && !$1.reports})
        }
        if !ascending {
            emailDataSorted = emailDataSorted.reversed()
        }
    }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        print("tableview sort descriptors changed")
        guard let sortDescriptor = tableView.sortDescriptors.first else { return }
        let ascending = sortDescriptor.ascending
        if let key = sortDescriptor.key,let order = CellIdentifier(rawValue: key) {
            sortData(by: order, ascending: ascending)
        }
        tableViewOutlet.reloadData()
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        DLog.log(.userInterface,"tableview number of rows \(emailData.count)")
        return emailData.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: CellIdentifier = .Map
        
        if tableColumn == tableViewOutlet.tableColumns[0] {
            cellIdentifier = CellIdentifier.Map
            text = emailDataSorted[row].map
        }
        if tableColumn == tableViewOutlet.tableColumns[1] {
            cellIdentifier = CellIdentifier.Email
            text = emailDataSorted[row].email
        }
        if tableColumn == tableViewOutlet.tableColumns[2] {
            cellIdentifier = CellIdentifier.Name
            text = emailDataSorted[row].name
        }
        if tableColumn == tableViewOutlet.tableColumns[3] {
            cellIdentifier = CellIdentifier.Alerts
            if emailDataSorted[row].alerts {
                text = "alerts"
            }
        }
        if tableColumn == tableViewOutlet.tableColumns[4] {
            cellIdentifier = CellIdentifier.Reports
            if emailDataSorted[row].reports {
                text = "reports"
            }
        }
        //print("cell identifier \(cellIdentifier) text \(text)")
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier.rawValue), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
