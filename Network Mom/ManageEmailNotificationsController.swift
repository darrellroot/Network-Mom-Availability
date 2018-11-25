//
//  ManageEmailNotificationsController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/20/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa

class ManageEmailNotificationsController: NSWindowController {

    @IBOutlet weak var mapNameOutlet: NSPopUpButton!
    @IBOutlet weak var emailAddressOutlet: NSPopUpButton!
    @IBOutlet weak var radioNoneOutlet: NSButton!
    @IBOutlet weak var radioAlertOutlet: NSButton!
    @IBOutlet weak var radioReportOutlet: NSButton!
    @IBOutlet weak var radioAlertReportOutlet: NSButton!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ManageEmailNotificationsController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        for map in appDelegate.maps {
            mapNameOutlet.addItem(withTitle: map.name)
        }
        for email in appDelegate.emails {
            emailAddressOutlet.addItem(withTitle: email.name)
        }
    }
    
    @IBAction func notificationRadioButtonChanged(_ sender: NSButton) {
    }
    
    
}
