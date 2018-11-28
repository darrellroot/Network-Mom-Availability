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
    @IBOutlet weak var emailSelectorOutlet: NSPopUpButton!
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
            emailSelectorOutlet.addItem(withTitle: "\(email.email) \(email.name)")
        }
        if appDelegate.emails.count > 0, let email = appDelegate.emails.first {
            setRadioButtons(email: email)
        }
    }
    
    @IBAction func emailSelectorButton(_ sender: NSPopUpButton) {
        let index = emailSelectorOutlet.indexOfSelectedItem
        //first we need to validate that the selection matches what we expect
        //this can be wrong if the appdelegate email list changed due to activity in other windows
        if let title = emailSelectorOutlet.selectedItem?.title, let titleEmail = title.components(separatedBy: " ").first {
            if appDelegate.emails.count > index && appDelegate.emails[index].email == titleEmail {
                // validation complete
                let email = appDelegate.emails[index]
                setRadioButtons(email: email)
            }
        }
    }
    
    private func setRadioButtons(email: EmailAddress) {
        if email.pagerOnly {
            radioReportOutlet.isEnabled = false
            radioAlertReportOutlet.isEnabled = false
        } else {
            radioReportOutlet.isEnabled = true
            radioAlertReportOutlet.isEnabled = true
        }
    }
    
    @IBAction func notificationRadioButtonChanged(_ sender: NSButton) {
    }
    
    
}
