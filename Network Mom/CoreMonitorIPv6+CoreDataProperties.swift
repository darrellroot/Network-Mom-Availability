//
//  CoreMonitorIPv6+CoreDataProperties.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/27/19.
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
    @NSManaged public var availabilityOneHourData: [Double]?
    @NSManaged public var availabilityOneHourTimestamp: [Int]?
    @NSManaged public var comment: String?
    @NSManaged public var frameHeight: Float
    @NSManaged public var frameWidth: Float
    @NSManaged public var frameX: Float
    @NSManaged public var frameY: Float
    @NSManaged public var hostname: String?
    @NSManaged public var ipv6String: String?
    @NSManaged public var latencyDayData: [Double]?
    @NSManaged public var latencyDayTimestamp: [Int]?
    @NSManaged public var latencyFiveMinuteData: [Double]?
    @NSManaged public var latencyFiveMinuteTimestamp: [Int]?
    @NSManaged public var latencyOneHourData: [Double]?
    @NSManaged public var latencyOneHourTimestamp: [Int]?
    @NSManaged public var coreMap: CoreMap?

}
