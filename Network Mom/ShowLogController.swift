//
//  ShowLogController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/16/18.
//

import Cocoa
import HeliumLogger
import LoggerAPI

class ShowLogController: NSWindowController {

    @IBOutlet var logTextOutlet: NSTextView!
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ShowLogController")
    }

    @IBAction func selectLogButton(_ sender: NSPopUpButton) {
        var logType: LoggerMessageType
        switch sender.indexOfSelectedItem {
        case 0:
            logType = .error
        case 1:
            logType = .warning
        case 2:
            logType = .info
        case 3:
            logType = .verbose
        case 4:
            logType = .debug
        case 5:
            logType = .exit
        case 6:
            logType = .entry
        default:
            print("should not get here")
            logType = .verbose
        }
        let logData = HeliumLogger.logData[logType]!.getData().joined()
            logTextOutlet.string = logData
    }
}
