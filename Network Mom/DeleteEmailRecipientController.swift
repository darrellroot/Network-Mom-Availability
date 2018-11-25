//
//  DeleteEmailRecipientController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/24/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class DeleteEmailRecipientController: NSWindowController {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var emailSelectorOutlet: NSPopUpButton!
    
    @IBOutlet weak var resultLabel: NSTextField!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("DeleteEmailRecipientController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func updateEmailList() {

        emailSelectorOutlet.removeAllItems()
        for email in appDelegate.emails {
            
            emailSelectorOutlet.addItem(withTitle: "\(email.email) \(email.name)")
        }
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        let index = emailSelectorOutlet.indexOfSelectedItem
        if let title = emailSelectorOutlet.selectedItem?.title, let titleEmail = title.components(separatedBy: " ").first {
            if appDelegate.emails.count > index && appDelegate.emails[index].name == titleEmail {
                appDelegate.emails.remove(at: index)
                DLog.log(.dataIntegrity, "Deleted email \(titleEmail) at index \(index)")
                updateEmailList()
            }
        }
    }
}

