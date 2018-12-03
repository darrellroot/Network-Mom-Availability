//
//  EmailServerController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/15/18.
//

import Cocoa
import SwiftSMTP
import DLog
import Security

class EmailServerController: NSWindowController {
    
    var smtp: SMTP!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EmailServerController")
    }
    
    @IBOutlet weak var serverHostnameOutlet: NSTextField!
    
    @IBOutlet weak var senderEmailUsernameOutlet: NSTextField!
    
    @IBOutlet weak var senderEmailPasswordOutlet: NSTextField!
    
    @IBOutlet weak var testDestinationEmailOutlet: NSTextField!
    
    @IBOutlet weak var emailResultOutlet: NSTextField!
    
    let userDefaults = UserDefaults.standard
    
    override func windowDidLoad() {
        super.windowDidLoad()
        DLog.log(.userInterface,"EmailServerController window loaded")
            emailResultOutlet.stringValue = ""
        if let emailServerHostname = userDefaults.object(forKey: Constants.emailServerHostname) as? String {
            serverHostnameOutlet.stringValue = emailServerHostname
        }
        if let emailServerUsername = userDefaults.object(forKey: Constants.emailServerUsername) as? String {
            senderEmailUsernameOutlet.stringValue = emailServerUsername
        }
        if let emailPassword = appDelegate.emailConfiguration?.password {
            senderEmailPasswordOutlet.stringValue = emailPassword
        }
    }
    
    @IBAction func clearEmailServerSettings(_ sender: NSButton) {
        serverHostnameOutlet.stringValue = ""
        senderEmailUsernameOutlet.stringValue = ""
        senderEmailPasswordOutlet.stringValue = ""
        testDestinationEmailOutlet.stringValue = ""
        userDefaults.removeObject(forKey: Constants.emailServerHostname)
        userDefaults.removeObject(forKey: Constants.emailServerUsername)
        clearEmailKeychain()
    }
    func clearEmailKeychain() {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrProtocol as String: Constants.networkmom]
        let status = SecItemDelete(query as CFDictionary)
        DLog.log(.mail,"mail credentials keychain delete status \(status)")
        DispatchQueue.main.async { [unowned self] in
            self.emailResultOutlet.stringValue = "Email credentials keychain deletion status \(status)"
        }
    }
    @IBAction func hostnamePressed(_ sender: Any) {
        DLog.log(.userInterface,"hostname pressed")
    }
    @IBAction func sendTestEmail(_ sender: NSButton) {
        DLog.log(.mail,"in sendEmail function")
        self.emailResultOutlet.stringValue = ""
        let hostname = serverHostnameOutlet.stringValue
        let senderEmail = senderEmailUsernameOutlet.stringValue
        let senderPassword = senderEmailPasswordOutlet.stringValue
        let destinationEmail = testDestinationEmailOutlet.stringValue
        let sender = Mail.User(name: "Network Mom", email: senderEmail)
        let droot = Mail.User(name: "Darrell Root", email: "darrellroot@mac.com")
        let destination = Mail.User(name: "Network Mom User", email: destinationEmail)
        let mail = Mail(from: sender, to: [droot], subject: "Test email from Network Mom", text: "If you got this, your email server configuration is working.")
        smtp = SMTP(hostname: hostname, email: senderEmail, password: senderPassword, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
        smtp.send(mail) { (error) in
            if let error = error {
                DLog.log(.mail,"email error \(error)")
                if let error = error as? SMTPError {
                    DispatchQueue.main.async { [unowned self] in self.emailResultOutlet.stringValue = error.description }
                } else {
                    DispatchQueue.main.async { [unowned self] in self.emailResultOutlet.stringValue = error.localizedDescription }
                }
            } else {
                self.userDefaults.set(hostname, forKey: Constants.emailServerHostname)
                self.userDefaults.set(senderEmail, forKey: Constants.emailServerUsername)
                self.appDelegate.emailConfiguration = EmailConfiguration(server: hostname, username: senderEmail, password: senderPassword)
                var status: OSStatus = 0
                var statusString = "unknown \(status)"
                if let senderPassword = senderPassword.data(using: String.Encoding.utf8) {
                    self.clearEmailKeychain()
                    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                                kSecAttrAccount as String: senderEmail,
                                                kSecAttrServer as String: hostname,
                                                kSecValueData as String: senderPassword,
                                                kSecAttrProtocol as String: Constants.networkmom]
                    status = SecItemAdd(query as CFDictionary, nil)
                    switch status {
                    case 0:
                        statusString = "successful"
                    case -25299:
                        statusString = "keychain already set"
                    default:
                        break
                    }
                    DLog.log(.mail,"mail credentials keychain status: \(statusString)")
                }
                DispatchQueue.main.async { [unowned self] in
                    self.emailResultOutlet.stringValue = "Email sent\nSettings saved\n keychain update status: \(statusString)"
                }
            }
        }
    }
}
