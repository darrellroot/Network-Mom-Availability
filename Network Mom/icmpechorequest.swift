//
//  extensions.swift
//  stevens-ch1-daytime
//
//  Created by Darrell Root on 10/4/18.
//  Copyright © 2018 Darrell Root. All rights reserved.
//

import Foundation

struct IcmpEchoRequest {
    var type: UInt8 = 8     /* type of message*/
    var code: UInt8 = 0    /* type sub code */
    var checkSum: UInt16 /* ones complement cksum of struct */
    var identifier: UInt16
    var sequenceNumber: UInt16
    var data: (UInt16,UInt16,UInt16,UInt16) = (0,0,0,0)
    
    var length: Int {
        return 16
    }
    
    init(id: UInt16, sequence: UInt16) {
        identifier = UInt16(bigEndian: id)
        sequenceNumber = UInt16(bigEndian: sequence)
        checkSum = 0
        checkSum = calcChecksum()
    }
    init() {
        identifier = UInt16(bigEndian: 1)
        sequenceNumber = UInt16(bigEndian: 1)
        checkSum = 0
        checkSum = calcChecksum()
    }
    func calcChecksum() -> UInt16 {
        var sum: UInt32 = UInt32(type) + UInt32(code) * 256 + UInt32(identifier) + UInt32(sequenceNumber) + UInt32(data.0) + UInt32(data.1) + UInt32(data.2) + UInt32(data.3)
        sum = (sum >> 16) + (sum & 0xffff)
        sum += (sum >> 16)
        let answer = sum & 0xffff
        let answer2: UInt16 = 65535 - UInt16(answer)
        return answer2
    }
}
/*
enum ICMPType: UInt8{
    case EchoReply = 0           // code is always 0
    case EchoRequest = 8            // code is always 0
}

struct ICMPHeader {
    var type: UInt8      /* type of message*/
    var code: UInt8      /* type sub code */
    var checkSum: UInt16 /* ones complement cksum of struct */
    var identifier: UInt16
    var sequenceNumber: UInt16
    var data:timeval
}
*/
func ipstring2in_addr(ipstring: String) -> in_addr_t? {
    let split = ipstring.components(separatedBy: ".")
    var ip: UInt32 = 0
    for octetString in split {
        if let octetInt = UInt8(octetString){
            ip = ip * 256
            ip = ip + UInt32(octetInt)
        } else {
            return nil
        }
    }
    return ip
}
/*
func ICMPPackageCreate(identifier:UInt16, sequenceNumber: UInt16, payloadSize: UInt32)-> NSData? {
    let packageDebug = false  // triggers print statements below
    
    var icmpType = ICMPType.EchoRequest.rawValue
    var icmpCode: UInt8 = 0
    var icmpChecksum: UInt16 = 0
    var icmpIdentifier = identifier
    var icmpSequence = sequenceNumber
    
    let packet = "baadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaadbaad"
    guard let packetData = packet.data(using: .utf8) else { return nil }
    var payload = NSData(data: packetData)
    payload = payload.subdata(with: NSRange(location: 0, length: Int(payloadSize))) as NSData
    guard let package = NSMutableData(capacity: MemoryLayout<ICMPHeader>.size + payload.length) else { return nil }
    package.replaceBytes(in: NSRange(location: 0, length: 1), withBytes: &icmpType)
    package.replaceBytes(in: NSRange(location: 1, length: 1), withBytes: &icmpCode)
    package.replaceBytes(in: NSRange(location: 2, length: 2), withBytes: &icmpChecksum)
    package.replaceBytes(in: NSRange(location: 4, length: 2), withBytes: &icmpIdentifier)
    package.replaceBytes(in: NSRange(location: 6, length: 2), withBytes: &icmpSequence)
    package.replaceBytes(in: NSRange(location: 8, length: payload.length), withBytes: payload.bytes)
    
    let bytes = package.mutableBytes
    icmpChecksum = checkSum(buffer: bytes, bufLen: package.length)
    package.replaceBytes(in: NSRange(location: 2, length: 2), withBytes: &icmpChecksum)
    if packageDebug { print("ping package: \(package)") }
    return package
}

@inline(__always) func checkSum(buffer: UnsafeMutableRawPointer, bufLen: Int) -> UInt16 {
    var bufLen = bufLen
    var checksum:UInt32 = 0
    var buf = buffer.assumingMemoryBound(to: UInt16.self)
    
    while bufLen > 1 {
        checksum += UInt32(buf.pointee)
        buf = buf.successor()
        bufLen -= MemoryLayout<UInt16>.size
    }
    
    if bufLen == 1 {
        checksum += UInt32(UnsafeMutablePointer<UInt16>(buf).pointee)
    }
    checksum = (checksum >> 16) + (checksum & 0xFFFF)
    checksum += checksum >> 16
    return ~UInt16(checksum)
}
*/
