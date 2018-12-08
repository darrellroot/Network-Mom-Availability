//
//  Array+extensions.swift
//  Network Mom
//
//  Created by Darrell Root on 12/8/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation
extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
