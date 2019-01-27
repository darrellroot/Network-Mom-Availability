//
//  Integer+extensions.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/23/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation
extension Int {
    public func squareRoot() -> Int {
        guard self >= 0 else { fatalError("Negative integer has no integer square root") }
        
        var lowerBound: Int = 0
        var uppperBound = self
        while lowerBound <= uppperBound {
            let middleBound = (lowerBound + uppperBound) / 2
            let middleBoundSquare = middleBound * middleBound
            
            if middleBoundSquare < self {
                lowerBound = middleBound + 1
            } else if middleBoundSquare > self {
                uppperBound = middleBound - 1
            } else {
                return middleBound
            }
        }
        return lowerBound - 1
    }
    
    public mutating func formSquareRoot() {
        self = squareRoot()
    }
}
