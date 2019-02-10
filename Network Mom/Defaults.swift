//
//  Defaults.swift
//  Network Mom
//
//  Created by Darrell Root on 11/28/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation

struct Defaults {
    static let emailTimerDuration = 300.0
    static let emailTimerTolerance = 10.0
    
    static let latencyStaticThreshold = 10.0
    static let latencyPercentThresholdRed = 1.80
    static let latencyPercentThresholdOrange = 1.50
    static let latencyPercentThresholdYellow = 1.20
    static let pingSweepDuration: Int = 20 //must be an integer multiple of pingTimerDuration

    static let pingTimerDuration: Int = 1

    static let trialPeriodSeconds: Double = 3600 * 24 * 30
    private init() {}
}
