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
    //static let CoreLicense = "CoreLicense"
    static let CoreLicense = "CoreLicense"
    static let GracePeriod = "GracePeriod"
    static let gracePeriodTransaction = "100"
    //static let gracePeriodDuration = 1800.0
    static let gracePeriodDuration = 3600.0 * 24.0 * 31.0
    //static let annualLicenseDuration = 3600.0 * 1.0 * 1.0
    static let annualLicenseDuration = 3600.0 * 24.0 * 366.0
    static let CoreMap = "CoreMap"
    static let CoreMonitorIPv4 = "CoreMonitorIPv4"
    static let CoreMonitorIPv6 = "CoreMonitorIPv6"
    
    //
    static let systemBeep = "System Beep"
    
    // Used for keychain search
    static let networkmom = "Network Mom"
    private init() {}
    
    // backup product information
    static let backupLocalizedProductTitle = "One Year License"
    static let backupLocalizedProductDescription = "Unlocks All Network Mom Availability Features"
}
