//
//  CoreMap+CoreDataProperties.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/27/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreMap {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreMap> {
        return NSFetchRequest<CoreMap>(entityName: "CoreMap")
    }

    @NSManaged public var availabilityDayData: [Double]?
    @NSManaged public var availabilityDayTimestamp: [Int]?
    @NSManaged public var availabilityFiveMinuteData: [Double]?
    @NSManaged public var availabilityFiveMinuteTimestamp: [Int]?
    @NSManaged public var availabilityOneHourData: [Double]?
    @NSManaged public var availabilityOneHourTimestamp: [Int]?
    @NSManaged public var emailAlerts: [String]?
    @NSManaged public var emailReports: [String]?
    @NSManaged public var frameHeight: Float
    @NSManaged public var frameWidth: Float
    @NSManaged public var frameX: Float
    @NSManaged public var frameY: Float
    @NSManaged public var name: String?
    @NSManaged public var ipv4monitors: Set<CoreMonitorIPv4>?
    @NSManaged public var ipv6monitors: Set<CoreMonitorIPv6>?
    //when rebuilding core data headers, you may need to specify the type like this:
    //@NSManaged public var ipv4monitors: Set<CoreMonitorIPv4>?
    //@NSManaged public var ipv6monitors: Set<CoreMonitorIPv6>?

}

// MARK: Generated accessors for ipv4monitors
extension CoreMap {

    @objc(addIpv4monitorsObject:)
    @NSManaged public func addToIpv4monitors(_ value: CoreMonitorIPv4)

    @objc(removeIpv4monitorsObject:)
    @NSManaged public func removeFromIpv4monitors(_ value: CoreMonitorIPv4)

    @objc(addIpv4monitors:)
    @NSManaged public func addToIpv4monitors(_ values: NSSet)

    @objc(removeIpv4monitors:)
    @NSManaged public func removeFromIpv4monitors(_ values: NSSet)

}

// MARK: Generated accessors for ipv6monitors
extension CoreMap {

    @objc(addIpv6monitorsObject:)
    @NSManaged public func addToIpv6monitors(_ value: CoreMonitorIPv6)

    @objc(removeIpv6monitorsObject:)
    @NSManaged public func removeFromIpv6monitors(_ value: CoreMonitorIPv6)

    @objc(addIpv6monitors:)
    @NSManaged public func addToIpv6monitors(_ values: NSSet)

    @objc(removeIpv6monitors:)
    @NSManaged public func removeFromIpv6monitors(_ values: NSSet)

}
