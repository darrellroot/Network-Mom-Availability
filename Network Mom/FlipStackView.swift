//
//  FlipStackView.swift
//  Network Mom
//
//  Created by Darrell Root on 11/10/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa

class FlipStackView: NSStackView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override var isFlipped: Bool {
        return true
    }

}
