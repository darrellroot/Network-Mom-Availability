//
//  CodableDataStructure.swift
//  Network Mom
//
//  Created by Darrell Root on 11/24/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//
// command to convert saved files between binary and xml format
// plutil -convert xml1 Preferences/com.apple.finder.plist
// see https://www.bignerdranch.com/blog/property-list-seralization/

/*import AppKit

class CodableDataStructure: Codable {
    enum CodingKeys: String, CodingKey {
        case maps
        //case emailAddresses
    }
    var maps: [MapWindowController]
    //var emailAddresses: [EmailAddress] = []
    init() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        maps = appDelegate.maps
        //emailAddresses = appDelegate.emails
    }
    required init(from decoder: Decoder) throws {
        //let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maps = (try? container.decode([MapWindowController].self, forKey: .maps)) ?? []
        //emailAddresses = (try? container.decode([EmailAddress].self, forKey: .emailAddresses)) ?? []
        //appDelegate.maps = maps
        //appDelegate.emails = emailAddresses
    }
}*/
