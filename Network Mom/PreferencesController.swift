//
//  preferencesController.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/31/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class PreferencesController: NSWindowController, NSWindowDelegate {

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    var currentSound: NSSound?
    var audioURLs: [URL] = []
    
    @IBOutlet weak var audioFrequencyOutlet: NSPopUpButton!
    @IBOutlet weak var enableAudioAlerts: NSButton!
    
    @IBOutlet weak var alertChooserOutlet: NSPopUpButton!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("PreferencesController")
    }

    func windowWillClose(_ notification: Notification) {
        appDelegate.preferencesController = nil
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        
        switch appDelegate.audioAlertFrequency {
        case 60:
            audioFrequencyOutlet.selectItem(withTag: 60)
        case 300:
            audioFrequencyOutlet.selectItem(withTag: 300)
        default:
            audioFrequencyOutlet.selectItem(at: 0)
        }
        audioURLs = (Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) ?? []).sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
        let audioName = appDelegate.audioName
        for url in audioURLs {
            alertChooserOutlet.addItem(withTitle: url.lastPathComponent)
        }
        alertChooserOutlet.addItem(withTitle: Constants.systemBeep)
        alertChooserOutlet.selectItem(withTitle: audioName)
        if alertChooserOutlet.selectedItem == nil {
            alertChooserOutlet.selectItem(withTitle: Constants.systemBeep)
        }
    }
    
    @IBAction func audioFrequencySelector(_ sender: NSPopUpButton) {
        switch sender.selectedItem?.tag ?? 0 {
        case 0:
            appDelegate.audioAlertFrequency = Int.max
        case 60:
            appDelegate.audioAlertFrequency = 60
        case 300:
            appDelegate.audioAlertFrequency = 300
        default:
            appDelegate.audioAlertFrequency = Int.max
            DLog.log(.userInterface,"Error: invalid audio frequency selector in preferences panel")
        }
    }
    @IBAction func testAudioAlert(_ sender: NSButton) {
        appDelegate.audioAlert(override: true)
    }
    func selectSound() {
        var newSound: NSSound?
        var newTitle: String?
        let chosenItem = alertChooserOutlet.indexOfSelectedItem
        
        if chosenItem < audioURLs.count {
            newSound = NSSound(contentsOf: audioURLs[chosenItem], byReference: false)
            newTitle = audioURLs[chosenItem].lastPathComponent
        } else {
            newSound = nil
            newTitle = Constants.systemBeep
        }
        appDelegate.setAudioSound(newSound: newSound, newTitle: newTitle)
    }
    @IBAction func alertChooserButton(_ sender: NSPopUpButton) {
        selectSound()
    }
}
