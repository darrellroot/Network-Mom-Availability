//
//  RRDAvailability.swift
//  Network Mom
//
//  Created by Darrell Root on 11/5/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Foundation

struct RRDGauge: Codable {
    static let maxData = 600
    static let fiveMinute = 60 * 5
    static let thirtyMinute = 60 * 30
    static let twoHour = 60 * 60 * 2
    static let day = 60 * 60 * 24
    
    private var currentStartTimestamp: [MonitorDataType: Int] = [:] // evenly divisible by 300
    private var currentNumerator: [MonitorDataType: Double] = [:]
    private var currentDenominator: [MonitorDataType: Double] = [:]
    
    private var fiveMinuteData = RRDBufferDouble(count: 600)
    private var thirtyMinuteData = RRDBufferDouble(count: 600)
    private var twoHourData = RRDBufferDouble(count: 600)
    private var dayData = RRDBufferDouble(count: 600)
    var lastFiveMinute: RRDData? {
        return fiveMinuteData.readRecent()
    }
    var lastThirtyMinute: RRDData? {
        return thirtyMinuteData.readRecent()
    }
    var lastDay: RRDData? {
        return dayData.readRecent()
    }

    var currentTime: Int!  // all mutating public functions must update currentTime when called
    
    init() {
        currentTime = Int(Date().timeIntervalSinceReferenceDate)
        for dataType in MonitorDataType.allCases {
            currentNumerator[dataType] = 0
            currentDenominator[dataType] = 0
            currentStartTimestamp[dataType] = currentTime / dataType.rawValue * dataType.rawValue
        }
    }
    mutating public func update(newData: Double) {
        currentTime = Int(Date().timeIntervalSinceReferenceDate)
        for dataType in MonitorDataType.allCases {
            let currentTimeInterval = currentTime / dataType.rawValue * dataType.rawValue
            if currentTimeInterval - currentStartTimestamp[dataType]! >= dataType.rawValue {
                dataUpdate(dataType: dataType)
            }
            guard currentTime - currentStartTimestamp[dataType]! < dataType.rawValue else {
                fatalError("current time \(String(describing: currentTime)) currentStartTimestamp \(String(describing: currentStartTimestamp[dataType])) dataType \(dataType)")
            }
            currentNumerator[dataType] = currentNumerator[dataType]! + newData
            currentDenominator[dataType] = currentDenominator[dataType]! + 1
        }
    }
    mutating private func dataUpdate(dataType: MonitorDataType) {
        //debugPrint("dataUpdate \(dataType)")
        while currentTime - currentStartTimestamp[dataType]! >= dataType.rawValue {
            var value: Double?
            if currentDenominator[dataType]! == 0 {
                value = nil
            } else {
                value = currentNumerator[dataType]! / currentDenominator[dataType]!
            }
            let newData = RRDData(timestamp: currentStartTimestamp[dataType]!, value: value)
            switch dataType {
            case .FiveMinute:
                self.fiveMinuteData.insert(newData)
            case .ThirtyMinute:
                self.thirtyMinuteData.insert(newData)
            case .TwoHour:
                self.twoHourData.insert(newData)
            case .OneDay:
                self.dayData.insert(newData)
            }
            currentStartTimestamp[dataType] = currentStartTimestamp[dataType]! + dataType.rawValue
            currentNumerator[dataType] = 0
            currentDenominator[dataType] = 0
            
        }
    }
    public func getData(dataType: MonitorDataType) -> [RRDData] {
        switch dataType {
        case .FiveMinute:
            return fiveMinuteData.getData()
        case .ThirtyMinute:
            return thirtyMinuteData.getData()
        case .TwoHour:
            return twoHourData.getData()
        case .OneDay:
            return dayData.getData()
        }
    }
}
