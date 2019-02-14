//
//  CoreLicense+CoreDataClass.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/13/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//
//

import Foundation
import CoreData
import DLog

@objc(CoreLicense)
public class CoreLicense: NSManagedObject {
    convenience init(context: NSManagedObjectContext, product: String, purchaseDate: Date, startDate: Date?, endDate: Date?, transactionIdentifier: String) {
        let entityDescription = NSEntityDescription.entity(forEntityName: Constants.CoreLicense, in: context)!
        self.init(entity: entityDescription, insertInto: context)
        self.product = product
        self.purchaseDate = purchaseDate
        let calculatedStartDate = startDate ?? purchaseDate
        self.startDate = calculatedStartDate
        switch product {
        case Constants.GracePeriod:
            self.endDate = calculatedStartDate + Constants.gracePeriodDuration
        case productIdentifiers.annual.rawValue:
            self.endDate = calculatedStartDate + Constants.annualLicenseDuration
        default:
            DLog.log(.license,"CoreLicense init error: invalid product identifier \(product)")
            self.endDate = calculatedStartDate + Constants.gracePeriodDuration
        }
        self.endDate = endDate ?? purchaseDate
        self.transactionIdentifier = transactionIdentifier
    }
    
    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

}
