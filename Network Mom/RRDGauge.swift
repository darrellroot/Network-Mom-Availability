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
        /*let currentTimeInterval = currentTime / RRDGauge.fiveMinute * RRDGauge.fiveMinute
        if currentTimeInterval - currentStartTimestamp >= RRDGauge.fiveMinute {
            fiveMinDataUpdate()
        }
        guard currentTime - currentStartTimestamp < 300 else {
            fatalError("current time - currentStartTimestamp > 300")
        }
        currentNumerator += newData
        currentDenominator += 1*/
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
        //removeOldData(dataType: dataType)
    }
/*    mutating private func fiveMinDataUpdate() {
        debugPrint("fiveMinDataUpdate")
        while currentTime - currentStartTimestamp >= 300 {
            var value: Double?
            if currentDenominator == 0 {
                value = nil
            } else {
                value = currentNumerator / currentDenominator
            }
            let newData = RRDData(timestamp: currentStartTimestamp, value: value)
            self.fiveMinuteData.insert(newData, at: 0)
            currentStartTimestamp += 300
            currentNumerator = 0
            currentDenominator = 0
        }
        removeOldData()
    }*/
/*    mutating private func removeOldData(dataType: MonitorDataType) {
        debugPrint("removeOldData type \(dataType)")
        var done = false
        while !done {
            var lastData: RRDData?
            switch dataType {
            case .FiveMinute:
                lastData = fiveMinuteData.last
            case .ThirtyMinute:
                lastData = thirtyMinuteData.last
            case .TwoHour:
                lastData = twoHourData.last
            case .OneDay:
                lastData = dayData.last
            }
            if let lastData = lastData {
                if currentTime - lastData.timestamp > dataType.rawValue * RRDGauge.maxData {
                    switch dataType {
                    case .FiveMinute:
                        fiveMinuteData.removeLast()
                    case .ThirtyMinute:
                        thirtyMinuteData.removeLast()
                    case .TwoHour:
                        twoHourData.removeLast()
                    case .OneDay:
                        dayData.removeLast()
                    }
                } else {
                    done = true
                }
            } else {
                done = true
            }
        }
    }*/
/*    mutating private func removeOldData() {
        debugPrint("removeOldData")
        var done = false
        while !done {
            if let lastData = fiveMinuteData.last {
                if currentTime - lastData.timestamp > RRDGauge.fiveMinute * RRDGauge.maxData {
                    fiveMinuteData.removeLast()
                } else {
                    done = true
                }
            } else {
                done = true
            }
        }
    }*/
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
/*    public func getFiveMinuteData() -> [RRDData] {
        return fiveMinuteData
    }*/
/*    func dataString() -> String {
        var retval : String = ""
        for data in fiveMinuteData {
            if let value = data.value {
                retval += "\(data.timestamp) \(value) "
            } else {
                retval += "\(data.timestamp) nil "
            }
        }
        return retval
    }*/
}
