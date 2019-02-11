//
//  EditMapController.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/10/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class EditMapController: NSWindowController {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EditMapController")
    }
    weak var mapDelegate: MapWindowController?

    @IBOutlet weak var mapFieldOutlet: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setName()
    }
    func windowDidClose(_ notification: Notification) {
        DLog.log(.userInterface,"Edit Map Controller did close")
        mapDelegate?.editMapController = nil
    }

    private func setName() {
        if let map = mapDelegate {
            mapFieldOutlet.stringValue = map.name
            window?.title = "Edit \(map.name) Map"
        }
    }
    
    @IBAction func mapFieldAction(_ sender: NSTextField) {
        let newName = sender.stringValue
        if newName != "" && appDelegate.mapNameIsUnique(name: newName) {
            mapDelegate?.name = newName
            setName()
        } else {
            if let oldName = mapDelegate?.name {
                sender.stringValue = oldName
            }
            let alert = NSAlert()
            alert.messageText = "Map name must be unique"
            alert.informativeText = "Map name must not be empty"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
