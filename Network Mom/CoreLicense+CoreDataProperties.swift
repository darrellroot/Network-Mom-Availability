//
//  CoreLicense+CoreDataProperties.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/13/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreLicense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreLicense> {
        return NSFetchRequest<CoreLicense>(entityName: "CoreLicense")
    }

    @NSManaged public var product: String
    @NSManaged public var purchaseDate: Date
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var transactionIdentifier: String

}
