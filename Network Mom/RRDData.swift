//
//  RRDData.swift
//  Network Mom
//
//  Created by Darrell Root on 11/12/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Foundation

public struct RRDData: Codable {
    var timestamp: Int
    var value: Double?
}
