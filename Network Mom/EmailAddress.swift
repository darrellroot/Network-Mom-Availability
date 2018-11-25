//
//  EmailAddress.swift
//  Network Mom
//
//  Created by Darrell Root on 11/19/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation
//import SwiftSMTP

class EmailAddress: Equatable, Hashable, Codable {
    var name: String
    var email: String
    var pagerOnly: Bool
    
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
}
