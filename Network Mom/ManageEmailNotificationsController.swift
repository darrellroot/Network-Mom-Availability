//
//  ManageEmailNotificationsController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/20/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa

class ManageEmailNotificationsController: NSWindowController {

    @IBOutlet weak var mapSelectorOutlet: NSPopUpButton!
    @IBOutlet weak var emailSelectorOutlet: NSPopUpButton!
    @IBOutlet weak var radioNoneOutlet: NSButton!
    @IBOutlet weak var radioAlertOutlet: NSButton!
    @IBOutlet weak var radioReportOutlet: NSButton!
    @IBOutlet weak var radioAlertReportOutlet: NSButton!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("ManageEmailNotificationsController")
    }
    
    // setup local copies so we dont need to monitor changes elsewhere
    var maps : [MapWindowController] = []
    var emails : [EmailAddress] = []

    override func windowDidLoad() {
        super.windowDidLoad()
        maps = appDelegate.maps
        emails = appDelegate.emails
        updateMenus()
        setRadioButtons()
    }
    
    private func updateMenus() {
        mapSelectorOutlet.removeAllItems()
        for map in maps {
            mapSelectorOutlet.addItem(withTitle: map.name)
        }
        emailSelectorOutlet.removeAllItems()
        for email in emails {
            emailSelectorOutlet.addItem(withTitle: "\(email.email) \(email.name)")
        }
    }
    
    @IBAction func emailSelectorButton(_ sender: NSPopUpButton) {
        setRadioButtons()
    }
    @IBAction func mapSelectorButton(_ sender: NSPopUpButton) {
        setRadioButtons()
    }
    
    private func setRadioButtons() {
        let mapIndex = mapSelectorOutlet.indexOfSelectedItem
        guard mapIndex >= 0 else { return }
        guard mapIndex < maps.count else { return }
        let map = maps[mapIndex]
        let emailIndex = emailSelectorOutlet.indexOfSelectedItem
        guard emailIndex >= 0 else { return }
        guard emailIndex < emails.count else { return }
        let email = emails[emailIndex]
        if email.pagerOnly {
            radioReportOutlet.isEnabled = false
            radioAlertReportOutlet.isEnabled = false
        } else {
            radioReportOutlet.isEnabled = true
            radioAlertReportOutlet.isEnabled = true
        }
        var reports = false
        if map.emailReports.contains(email.email) {
            reports = true
        }
        var alerts = false
        if map.emailAlerts.contains(email.email) {
            alerts = true
        }
        switch (alerts,reports) {
        case (false, false):
            radioNoneOutlet.state = .on
        case (true, false):
            radioAlertOutlet.state = .on
        case (false, true):
            radioReportOutlet.state = .on
        case (true, true):
            radioAlertReportOutlet.state = .on
        }
    }
    
    @IBAction func notificationRadioButtonChanged(_ sender: NSButton) {
        let mapIndex = mapSelectorOutlet.indexOfSelectedItem
        guard mapIndex < maps.count else { return }
        let map = maps[mapIndex]
        let emailIndex = emailSelectorOutlet.indexOfSelectedItem
        guard emailIndex < emails.count else { return }
        let email = emails[emailIndex]
        var reports = false
        let reportIndex = map.emailReports.firstIndex(of: email.email)
        let alertIndex = map.emailAlerts.firstIndex(of: email.email)
        
        if radioNoneOutlet.state == .on {
            if let reportIndex = reportIndex {
                map.emailReports.remove(at: reportIndex)
            }
            if let alertIndex = alertIndex {
                map.emailAlerts.remove(at: alertIndex)
            }
        }
        if radioAlertOutlet.state == .on {
            if let reportIndex = reportIndex {
                map.emailReports.remove(at: reportIndex)
            }
            if alertIndex == nil {
                map.emailAlerts.append(email.email)
            }
        }
        if radioReportOutlet.state == .on {
            if let alertIndex = alertIndex {
                map.emailAlerts.remove(at: alertIndex)
            }
            if reportIndex == nil {
                map.emailReports.append(email.email)
            }
        }
        if radioAlertReportOutlet.state == .on {
            if alertIndex == nil {
                map.emailAlerts.append(email.email)
            }
            if reportIndex == nil {
                map.emailReports.append(email.email)
            }
        }
    }
}
