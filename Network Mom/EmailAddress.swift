//
//  EmailAddress.swift
//  Network Mom
//
//  Created by Darrell Root on 11/19/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import AppKit
import SwiftSMTP
import DLog

class EmailAddress: Equatable, Hashable, Codable {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var name: String
    var email: String
    var pagerOnly: Bool
    var pendingNotifications: [EmailNotification] = []
    
    private enum CodingKeys: String, CodingKey {
        case name
        case email
        case pagerOnly
    }
    var code: Int {
        // A deterministic 4-digit code to validate that the user can receive
        // emails to this address
        // this code is not currently used but kept here to document our deterministic hash
        return abs(email.djb2hash % 10000)
    }
/*    var user: Mail.User {
        let user = Mail.User(name: name, email: email)
        return user
    }*/
    
    public init(name: String, email: String, pagerOnly: Bool) {
        self.name = name
        self.email = email
        self.pagerOnly = pagerOnly
    }
    static func == (lhs: EmailAddress, rhs: EmailAddress) -> Bool {
        if lhs.email == rhs.email {
            return true
        } else {
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
    public func emailAlert() {
        if pendingNotifications.isEmpty { return }
        if let emailConfiguration = appDelegate.emailConfiguration {
            let sender = Mail.User(name: "Network Mom", email: emailConfiguration.username)
            let recipient = Mail.User(name: self.name, email: self.email)
            var message = ""
            for notification in pendingNotifications {
                message = message + notification.description + "\n"
            }
            pendingNotifications = []
            let mail = Mail(from: sender, to: [recipient], subject: "Network Mom Alert", text: message)
            let smtp = SMTP(hostname: emailConfiguration.server, email: emailConfiguration.username, password: emailConfiguration.password, port: 587, tlsMode: .requireSTARTTLS, tlsConfiguration: nil, authMethods: [], domainName: "localhost")
            smtp.send(mail) { (error) in
                if let error = error {
                    DLog.log(.mail,"email error \(error)")
                    if let error = error as? SMTPError {
                        DLog.log(.mail,error.description)
                    } else {
                        DLog.log(.mail,error.localizedDescription)
                    }
                } else {
                    DLog.log(.mail,"alert mail sent successfully")
                }
            }
        }
    }
}
