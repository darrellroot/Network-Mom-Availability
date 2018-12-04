//
//  EmailNotificationConfigurationReportController.swift
//  Network Mom
//
//  Created by Darrell Root on 12/3/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class EmailNotificationConfigurationReportController: NSWindowController {

    private struct emailDataLine {
        let map: String
        var name: String
        let email: String
        var alerts: Bool
        var reports: Bool
    }
    
    private var emailData: [emailDataLine] = []
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var tableViewOutlet: NSTableView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EmailNotificationConfigurationReportController")
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
            tableViewOutlet.delegate = self
            tableViewOutlet.dataSource = self
            tableViewOutlet.reloadData()
        }
    }
}

extension EmailNotificationConfigurationReportController: NSTableViewDataSource, NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let Map = "Map"
        static let Email = "Email"
        static let Name = "Name"
        static let Alerts = "Alerts"
        static let Reports = "Reports"
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        DLog.log(.userInterface,"tableview number of rows \(emailData.count)")
        return emailData.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableViewOutlet.tableColumns[0] {
            cellIdentifier = CellIdentifiers.Map
            text = emailData[row].map
        }
        if tableColumn == tableViewOutlet.tableColumns[1] {
            cellIdentifier = CellIdentifiers.Email
            text = emailData[row].email
        }
        if tableColumn == tableViewOutlet.tableColumns[2] {
            cellIdentifier = CellIdentifiers.Name
            text = emailData[row].name
        }
        if tableColumn == tableViewOutlet.tableColumns[3] {
            cellIdentifier = CellIdentifiers.Alerts
            if emailData[row].alerts {
                text = "alerts"
            }
        }
        if tableColumn == tableViewOutlet.tableColumns[4] {
            cellIdentifier = CellIdentifiers.Reports
            if emailData[row].reports {
                text = "reports"
            }
        }
        print("cell identifier \(cellIdentifier) text \(text)")
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
