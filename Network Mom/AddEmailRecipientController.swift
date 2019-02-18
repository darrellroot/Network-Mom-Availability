//
//  AddEmailRecipientController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/19/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import SwiftSMTP
import DLog

class AddEmailRecipientController: NSWindowController, NSWindowDelegate {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var emailNameOutlet: NSTextField!
    @IBOutlet weak var emailAddressOutlet: NSTextField!
    @IBOutlet weak var emailTypeOutlet: NSPopUpButton!
    @IBOutlet weak var emailResultOutlet: NSTextField!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AddEmailRecipientController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        emailResultOutlet.stringValue = ""
        emailNameOutlet.stringValue = ""
        if appDelegate.emailConfiguration == nil {
            self.emailResultOutlet.stringValue = "Warning: No server/sender email configuration.\nYou will be unable to add email recipients.\nUse the \"Notifications->Configure Email Server and Sender\" menu item."
        }
    }
    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface,"addemailrecipientcontroller closing")
        appDelegate.addEmailRecipientControllers.remove(object: self)
    }
    
    @IBAction func testEmailButton(_ sender: NSButton) {
        let name = emailNameOutlet.stringValue
        if name == "" {
            emailResultOutlet.stringValue = "Please enter the email recipient name"
            return
        }
        let address = emailAddressOutlet.stringValue
        if validateEmail(candidate: address) == false {
            emailResultOutlet.stringValue = "Invalid email format"
            return
        }
        let code = abs(address.djb2hash % 10000)
        
        guard let emailConfiguration = appDelegate.emailConfiguration else {
            DLog.log(.mail,"Unable to send test email, No email configuration")
            self.emailResultOutlet.stringValue = "Unable to send test/permission email.\nNo server/sender email configuration.\nUse the \"Notifications->Configure Email Server and Sender\" menu item."
            return
        }
        let sender = Mail.User(name: "Network Mom", email: emailConfiguration.username)
        let recipient = Mail.User(name: name, email: address)
        let text = """
Your Network Mom permission code is \(code)

Network Mom Availability is a MacOS application which monitors network devices to measure their availability and latency.

\(sender.name ?? "") \(sender.email) would like to add you to automated alerts and/or reports from a Network Mom monitoring station.

If you agree, send the code above back to \(sender.email).
"""
        let mail = Mail(from: sender, to: [recipient], subject: "Your Network Mom permission code is \(code)", text: text)
        let smtp = SMTP(hostname: emailConfiguration.server, email: emailConfiguration.username, password: emailConfiguration.password, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            smtp.send(mail) { (error) in
                if let error = error {
                    DLog.log(.mail,"email error \(error)")
                    if let error = error as? SMTPError {
                        DispatchQueue.main.async { [unowned self] in self.emailResultOutlet.stringValue = error.description }
                    } else {
                        DispatchQueue.main.async { [unowned self] in self.emailResultOutlet.stringValue = error.localizedDescription }
                    }
                } else {
                    DLog.log(.mail,"mail sent successfully")
                    DispatchQueue.main.async { [unowned self] in
                        self.emailResultOutlet.stringValue = "Permission Code Emailed Successfully"
                    }
                }
            }
        }
    }
    
    @IBAction func permissionCodeEntered(_ sender: NSTextField) {
        let code1 = abs(emailAddressOutlet.stringValue.djb2hash % 10000)
        let code2 = sender.intValue
        guard code1 == code2 else {
            emailResultOutlet.stringValue = "Code does not match"
            return
        }
        emailResultOutlet.stringValue = "Code matches"
        var pagerOnly: Bool
        //switch emailTypeOutlet.indexOfSelectedItem {
        switch emailTypeOutlet.selectedTag() {
        case 1: // email
            pagerOnly = false
        case 2: // pager
            pagerOnly = true
        default:
            // should not get here
            pagerOnly = false
        }
        for email in appDelegate.emails {
            if email.email == emailAddressOutlet.stringValue {
                emailResultOutlet.stringValue = "Updated existing email recipient"
                if emailNameOutlet.stringValue != "" {
                    email.name = emailNameOutlet.stringValue
                } else {
                    emailNameOutlet.stringValue = email.name
                }
                email.pagerOnly = pagerOnly
                return
            }
        }
        // if we got here, we need to create a new email
        let newEmail = EmailAddress(name: emailNameOutlet.stringValue, email: emailAddressOutlet.stringValue, pagerOnly: pagerOnly, context: appDelegate.managedContext)
            appDelegate.emails.append(newEmail)
            emailResultOutlet.stringValue = "Created new email recipient"
    }
    
    private func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
}
