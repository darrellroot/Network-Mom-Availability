//
//  String+extensions.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/11/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation

extension String {
    var ipv4address: String? {
        let split = self.components(separatedBy: ".")
        guard split.count == 4 else { return nil}
        guard let octet1 = UInt8(split[0]) else { return nil }
        guard let octet2 = UInt8(split[1]) else { return nil }
        guard let octet3 = UInt8(split[2]) else { return nil }
        guard let octet4 = UInt8(split[3]) else { return nil }
        guard octet1 < 224 else { return nil }
        guard octet1 > 0 else { return nil }
        return "\(octet1).\(octet2).\(octet3).\(octet4)"
    }
    var ipv4 : UInt32? {
        let split = self.components(separatedBy: ".")
        guard split.count == 4 else { return nil}
        guard let octet1 = UInt8(split[0]) else { return nil }
        guard let octet2 = UInt8(split[1]) else { return nil }
        guard let octet3 = UInt8(split[2]) else { return nil }
        guard let octet4 = UInt8(split[3]) else { return nil }
        guard octet1 < 224 else { return nil }
        guard octet1 > 0 else { return nil }
        return UInt32(octet4) + UInt32(octet3) * 256 + UInt32(octet2) * 256 * 256 + UInt32(octet1) * 256 * 256 * 256
    }
}
