//
//  Constants.swift
//  Network Mom
//
//  Created by Darrell Root on 11/18/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation

struct Constants {
    // UserDefault key constants
    static let emailServerHostname = "emailServerHostname"
    static let emailServerUsername = "emailServerUsername"
    static let audioAlertFrequency = "audioAlertFrequency"
    static let audioName = "audioName"
    // End UserDefault key constants
    // Core data entities
    static let CoreEmailAddress = "CoreEmailAddress"
    static let CoreLicense = "CoreLicense"
    static let CoreMap = "CoreMap"
    static let CoreMonitorIPv4 = "CoreMonitorIPv4"
    static let CoreMonitorIPv6 = "CoreMonitorIPv6"
    
    //
    static let systemBeep = "System Beep"
    
    // Used for keychain search
    static let networkmom = "Network Mom"
    private init() {}
}
