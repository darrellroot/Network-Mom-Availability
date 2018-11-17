//
//  ShowLogController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/16/18.
//

import Cocoa
import HeliumLogger
import LoggerAPI
import DLog

class ShowLogController: NSWindowController {

    @IBOutlet weak var logMenuOutlet: NSMenu!

    @IBOutlet var logTextOutlet: NSTextView!
    override func windowDidLoad() {
        super.windowDidLoad()
        for category in DLogCategories.allCases {
            let newMenuItem = NSMenuItem(title: category.rawValue, action: nil, keyEquivalent: "")
            logMenuOutlet.addItem(newMenuItem)
        }
        if let logData = DLog.logdata[DLogCategories.allCases.first!]?.getData().joined() {
            logTextOutlet.string = logData
        }
    }
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ShowLogController")
    }

    
    @IBAction func selectLogButton(_ sender: NSPopUpButton) {
        print("select log selected")
        
        if let title = sender.titleOfSelectedItem {
            print("log title is \(title)")
            for category in DLogCategories.allCases {
                if title == category.rawValue {
                    if let logData = DLog.logdata[category]?.getData().joined() {
                        logTextOutlet.string = logData
                    }
                }
            }
        }
    }
}
