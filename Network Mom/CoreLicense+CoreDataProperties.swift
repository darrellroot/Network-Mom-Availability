//
//  CoreLicense+CoreDataProperties.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/7/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreLicense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreLicense> {
        return NSFetchRequest<CoreLicense>(entityName: "CoreLicense")
    }

    @NSManaged public var firstInstallDate: NSDate?
    @NSManaged public var lastLicenseDate: NSDate?
    @NSManaged public var trialSeconds: Double

}
