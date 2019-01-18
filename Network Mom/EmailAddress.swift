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
import CoreData

class EmailAddress: Equatable, Hashable, Codable {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var name: String {
        get {
            if let name1 = coreEmailAddress?.name {
                return name1
            } else {
                return "error"
            }
        }
        set {
            coreEmailAddress?.name = newValue
        }
    }
    var email: String {
        get {
            if let email1 = coreEmailAddress?.email {
                return email1
            } else {
                return "error@nowhere.com"
            }
        }
        set {
            coreEmailAddress?.email = newValue
        }
    }
    var pagerOnly: Bool {
        get {
            if let pagerOnly = coreEmailAddress?.pagerOnly {
                return pagerOnly
            } else {
                return false  // should not get here, but returning reasonable value
            }
        } set {
            coreEmailAddress?.pagerOnly = newValue
        }
    }
    var pendingNotifications: [EmailNotification] = []
    
    var coreEmailAddress: CoreEmailAddress?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case email
        case pagerOnly
    }
/*    func makeCore(context: NSManagedObjectContext) -> CoreEmailAddress {
        let coreEmail = CoreEmailAddress(context: context)
        coreEmail.email = self.email
        coreEmail.name = self.name
        coreEmail.pagerOnly = self.pagerOnly
        return coreEmail
    }*/
    var code: Int {
        // A deterministic 4-digit code to validate that the user can receive
        // emails to this address
        // this code is not currently used but kept here to document our deterministic hash
        return abs(email.djb2hash % 10000)
    }
    
    deinit {
        if let coreEmailAddress = coreEmailAddress {
            coreEmailAddress.managedObjectContext?.delete(coreEmailAddress)
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.pagerOnly, forKey: .pagerOnly)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let context = appDelegate.managedContext else {
            DLog.log(.dataIntegrity, "Unable to decode Email Address, no managed core data context")
            throw NetworkMomError.noCoreDataContext
        }
        coreEmailAddress = CoreEmailAddress(context: context)
        coreEmailAddress?.name = try container.decode(String.self, forKey: .name)
        coreEmailAddress?.email = try container.decode(String.self, forKey: .email)
        coreEmailAddress?.pagerOnly = try container.decode(Bool.self, forKey: .pagerOnly)
        
    }
    public init(name: String, email: String, pagerOnly: Bool, context: NSManagedObjectContext) {
        coreEmailAddress = CoreEmailAddress(context: context)
        coreEmailAddress?.name = name
        coreEmailAddress?.email = email
        coreEmailAddress?.pagerOnly = pagerOnly
    }
    public init(coreEmailAddress: CoreEmailAddress, context: NSManagedObjectContext) {
        self.coreEmailAddress = coreEmailAddress
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
