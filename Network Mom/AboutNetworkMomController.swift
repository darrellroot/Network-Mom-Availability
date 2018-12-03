//
//  AboutNetworkMom.swift
//  Network Mom
//
//  Created by Darrell Root on 12/2/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa

class AboutNetworkMomController: NSWindowController {

    @IBOutlet var aboutTextView: NSTextView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AboutNetworkMomController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        aboutTextView.string = """
        Network Mom is written by Darrell Root and published by Darrell Root LLC.  Copyright 2019.  All rights reserved.
        
        IT engineers need an easy way to know what devices are up and what devices are down.  The best way to improve availability is to measure availability.  WAN engineers need to monitor network latency.  Outage alerts and availability reports should be easy to setup.
        
        Network Mom attempts to meet these requirements so engineers can keep an eye on their network.
        
        Please email feedback and feature requests to darrellroot@mac.com.
        """
    }
}
