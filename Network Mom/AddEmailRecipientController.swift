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

class AddEmailRecipientController: NSWindowController {

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
        
        if let emailConfiguration = appDelegate.emailConfiguration {
            let sender = Mail.User(name: "Network Mom", email: emailConfiguration.username)
            let recipient = Mail.User(name: name, email: address)
            let mail = Mail(from: sender, to: [recipient], subject: "Your Network Mom validation code is \(code)", text: "Enter this code in Network Mom to enable email alerts and reports.")
            let smtp = SMTP(hostname: emailConfiguration.server, email: emailConfiguration.username, password: emailConfiguration.password, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
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
                        self.emailResultOutlet.stringValue = "Validation Code Emailed Successfully"
                    }
                }
            }
        }
    }
    
    @IBAction func validationCodeEntered(_ sender: NSTextField) {
        let code1 = abs(emailAddressOutlet.stringValue.djb2hash % 10000)
        let code2 = sender.intValue
        guard code1 == code2 else {
            emailResultOutlet.stringValue = "Code does not match"
            return
        }
        emailResultOutlet.stringValue = "Code matches"
        var pagerOnly: Bool
        switch emailTypeOutlet.indexOfSelectedItem {
        case 0:
            pagerOnly = true
        case 1:
            pagerOnly = false
        default:
            // should not get here
            pagerOnly = false
        }
        if let email = appDelegate.emails[emailAddressOutlet.stringValue] {
            emailResultOutlet.stringValue = "Updated existing email recipient"
            if emailNameOutlet.stringValue != "" {
                email.name = emailNameOutlet.stringValue
            }
            email.pagerOnly = pagerOnly
        } else {
            let newEmail = EmailAddress(name: emailNameOutlet.stringValue, email: emailAddressOutlet.stringValue, pagerOnly: pagerOnly)
            appDelegate.emails[emailAddressOutlet.stringValue] = newEmail
            emailResultOutlet.stringValue = "Created new email recipient"
        }
    }
    
    private func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
}
