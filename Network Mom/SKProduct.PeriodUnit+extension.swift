//
//  SKProduct.PeriodUnit+extension.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/8/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import StoreKit

extension SKProduct.PeriodUnit {
    var string: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }
}
