//
//  CoreMonitorIPv6+CoreDataProperties.swift
//  Network Mom
//
//  Created by Darrell Root on 1/15/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreMonitorIPv6 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreMonitorIPv6> {
        return NSFetchRequest<CoreMonitorIPv6>(entityName: "CoreMonitorIPv6")
    }

    @NSManaged public var availabilityDayData: [Double]?
    @NSManaged public var availabilityDayTimestamp: [Int]?
    @NSManaged public var availabilityFiveMinuteData: [Double]?
    @NSManaged public var availabilityFiveMinuteTimestamp: [Int]?
    @NSManaged public var availabilityThirtyMinuteData: [Double]?
    @NSManaged public var availabilityThirtyMinuteTimestamp: [Int]?
    @NSManaged public var availabilityTwoHourData: [Double]?
    @NSManaged public var availabilityTwoHourTimestamp: [Int]?
    @NSManaged public var comment: String?
    @NSManaged public var frameHeight: Float
    @NSManaged public var frameWidth: Float
    @NSManaged public var frameX: Float
    @NSManaged public var frameY: Float
    @NSManaged public var hostname: String?
    @NSManaged public var ipv6String: String?
    @NSManaged public var latencyDayData: [Double]?
    @NSManaged public var latencyDayTimestamp: [Int]?
    @NSManaged public var latencyEnabled: Bool
    @NSManaged public var latencyFiveMinuteData: [Double]?
    @NSManaged public var latencyFiveMinuteTimestamp: [Int]?
    @NSManaged public var latencyThirtyMinuteData: [Double]?
    @NSManaged public var latencyThirtyMinuteTimestamp: [Int]?
    @NSManaged public var latencyTwoHourData: [Double]?
    @NSManaged public var latencyTwoHourTimestamp: [Int]?
    @NSManaged public var coreMap: CoreMap?

}
