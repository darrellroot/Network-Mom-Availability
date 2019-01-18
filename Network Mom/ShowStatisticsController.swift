//
//  ShowStatisticsController.swift
//  Network Mom
//
//  Created by Darrell Root on 12/8/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class ShowStatisticsController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var printOperation: NSPrintOperation!
    var items: [String] = []
    var numbers: [Int] = []
    
    @IBOutlet weak var tableViewOutlet: NSTableView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ShowStatisticsController")
    }
    
    fileprivate enum CellIdentifier: String {
        case Item = "Item"
        case Number = "Number"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        items.append("Maps")
        numbers.append(appDelegate.maps.count)
        
        items.append("Monitors")
        var total = 0
        for map in appDelegate.maps {
            total += map.monitors.count
        }
        numbers.append(total)
        
        items.append("Monitor Views")
        total = 0
        for map in appDelegate.maps {
            total += map.monitorViews.count
        }
        numbers.append(total)
        
        items.append("Email Destinations")
        numbers.append(appDelegate.emails.count)
        
        //items.append("Core Data Email Destinations")
        //numbers.append(appDelegate.coreEmails.count)
        
        items.append("Add Email Recipient Windows")
        numbers.append(appDelegate.addEmailRecipientControllers.count)
        
        items.append("Delete Email Recipient Windows")
        numbers.append(appDelegate.deleteEmailRecipientControllers.count)
        
        items.append("Email Notification Configuration Reports")
        numbers.append(appDelegate.emailNotificationConfigurationReportControllers.count)
        
        items.append("Manage Email Notification Windows")
        numbers.append(appDelegate.manageEmailNotificationsControllers.count)
        
        items.append("Show Log Windows")
        numbers.append(appDelegate.showLogControllers.count)
        
        items.append("Show Statistics Windows")
        numbers.append(appDelegate.showStatisticsControllers.count)
        
        tableViewOutlet.reloadData()

    }
    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface,"Show Statistics Window Closing")
        appDelegate.showStatisticsControllers.remove(object: self)
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    //does not work
    /*@IBAction func print(_ sender: Any) {
        DLog.log(.userInterface,"Printing statistics window")
        if let view = window?.contentView {
            printOperation = NSPrintOperation(view: view)
            printOperation.showsPrintPanel = false
            //printOperation.showsProgressPanel = true
            printOperation.run()
        }
    }*/
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text = ""
        var cellIdentifier: CellIdentifier = .Item
        
        if tableColumn == tableViewOutlet.tableColumns[0] {
            cellIdentifier = CellIdentifier.Item
            text = items[row]
            print("column 0")
        }
        if tableColumn == tableViewOutlet.tableColumns[1] {
            cellIdentifier = CellIdentifier.Number
            text = "\(numbers[row])"
            print("column 1")
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier.rawValue), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
