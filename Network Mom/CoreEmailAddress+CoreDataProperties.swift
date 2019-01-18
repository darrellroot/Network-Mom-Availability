//
//  CoreEmailAddress+CoreDataProperties.swift
//  Network Mom
//
//  Created by Darrell Root on 1/14/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreEmailAddress {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreEmailAddress> {
        return NSFetchRequest<CoreEmailAddress>(entityName: "CoreEmailAddress")
    }

    @NSManaged public var email: String?
    @NSManaged public var name: String?
    @NSManaged public var pagerOnly: Bool

}
