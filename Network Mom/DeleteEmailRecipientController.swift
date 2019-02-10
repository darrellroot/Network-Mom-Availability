//
//  DeleteEmailRecipientController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/24/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class DeleteEmailRecipientController: NSWindowController, NSWindowDelegate {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var emailSelectorOutlet: NSPopUpButton!
    
    @IBOutlet weak var resultLabel: NSTextField!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("DeleteEmailRecipientController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        resultLabel.stringValue = ""
        updateEmailList()
    }
    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface,"Deleting email recipient controller")
        appDelegate.deleteEmailRecipientControllers.remove(object: self)
    }
    
    func updateEmailList() {
        emailSelectorOutlet.removeAllItems()
        for email in appDelegate.emails {
            emailSelectorOutlet.addItem(withTitle: "\(email.email) \(email.name)")
        }
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        DLog.log(.userInterface,"Deleting email address")
        resultLabel.stringValue = "Attempted to delete email"
        if let title = emailSelectorOutlet.selectedItem?.title, let titleEmail = title.components(separatedBy: " ").first {
            appDelegate.deleteEmail(addressToDelete: titleEmail)
        }
        updateEmailList()
    }
}

