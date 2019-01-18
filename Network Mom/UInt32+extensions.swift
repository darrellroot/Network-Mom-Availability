//
//  UInt32+extensions.swift
//  Network Mom
//
//  Created by Darrell Root on 1/16/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation
extension UInt32 {
    var ipv4string: String {
        let octet4 = self % 256
        let octet3 = self / 256 % 256
        let octet2 = self / 256 / 256 % 256
        let octet1 = self / 256 / 256 / 256 % 256
        return "\(octet1).\(octet2).\(octet3).\(octet4)"
    }
}
