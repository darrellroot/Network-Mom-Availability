//
//  Collection+extensions.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/9/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation
extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
