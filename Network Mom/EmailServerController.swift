//
//  EmailServerController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/15/18.
//

import Cocoa
import SwiftSMTP
import DLog

class EmailServerController: NSWindowController {
    
    var smtp: SMTP!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EmailServerController")
    }

    @IBOutlet weak var serverHostnameOutlet: NSTextField!
    
    @IBOutlet weak var senderEmailUsernameOutlet: NSTextField!
    
    @IBOutlet weak var senderEmailPasswordOutlet: NSTextField!
    
    @IBOutlet weak var testDestinationEmailOutlet: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        DLog.log(.userInterface,"EmailServerController window loaded")
    }
    
    @IBAction func hostnamePressed(_ sender: Any) {
        DLog.log(.userInterface,"hostname pressed")
    }
    @IBAction func sendTestEmail(_ sender: NSButton) {
        DLog.log(.mail,"in sendEmail function")
        let hostname = serverHostnameOutlet.stringValue
        let senderEmail = senderEmailUsernameOutlet.stringValue
        let senderPassword = senderEmailPasswordOutlet.stringValue
        let destinationEmail = testDestinationEmailOutlet.stringValue
        let sender = Mail.User(name: "Network Mom", email: senderEmail)
        let droot = Mail.User(name: "Darrell Root", email: "darrellroot@mac.com")
        let destination = Mail.User(name: "Network Mom User", email: destinationEmail)
        let mail = Mail(from: sender, to: [droot], subject: "My program can now email you", text: "How is your application?")
        smtp = SMTP(hostname: hostname, email: senderEmail, password: senderPassword, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
        smtp.send(mail) { (error) in
            if let error = error {
                DLog.log(.mail,"email error \(error)")
            }
        }
    }
}
