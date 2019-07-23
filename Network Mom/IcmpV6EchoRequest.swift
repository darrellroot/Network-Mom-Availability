//
//  ICMPv6EchoRequest.swift
//  Network Mom 2
//
//  Created by Darrell Root on 10/22/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation


struct IcmpV6EchoRequest {
    var type: UInt8 = 128
    var code: UInt8 = 0
    var checkSum: UInt16 = 0
    var identifier: UInt16
    var sequenceNumber: UInt16
    var data: (UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32) = (0,0,0,0,0,0,0,0)

    var length: Int {
        return 40
    }

    init(id: UInt16, sequence: UInt16) {
        identifier = UInt16(bigEndian: id)
        sequenceNumber = UInt16(bigEndian: sequence)
        checkSum = 0
        //checkSum = calcChecksum()
    }
    init() {
        identifier = UInt16(bigEndian: 1)
        sequenceNumber = UInt16(bigEndian: 1)
        checkSum = 0
        //checkSum = calcChecksum()
    }

}
