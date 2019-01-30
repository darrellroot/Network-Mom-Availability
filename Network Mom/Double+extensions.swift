//
//  Double+extensions.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/28/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation

extension Double {
    var percentThree: String {
        return String(format: "%.3f",self * 100.0)
    }
    var twoPlaces: String {
        return String(format: "%.2f",self)
    }
    var threePlaces: String {
        return String(format: "%.3f",self)
    }
}
