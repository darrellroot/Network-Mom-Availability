//
//  ManageEmailNotificationsController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/20/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog

class ManageEmailNotificationsController: NSWindowController, NSWindowDelegate {

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
    //var emails : [EmailAddress] = []

    override func windowDidLoad() {
        super.windowDidLoad()
        maps = appDelegate.maps
        //emails = appDelegate.emails
        updateMenus()
        setRadioButtons()
    }
    
    func windowWillClose(_ notification: Notification) {
        DLog.log(.userInterface,"Closing manage email notifications controller window")
        appDelegate.manageEmailNotificationsControllers.remove(object: self)
    }
    
    private func updateMenus() {
        mapSelectorOutlet.removeAllItems()
        for map in maps {
            mapSelectorOutlet.addItem(withTitle: map.name)
        }
        emailSelectorOutlet.removeAllItems()
        for email in appDelegate.emails {
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
        let emailIndex = emailSelectorOutlet.indexOfSelectedItem
        if maps.count == 0 || appDelegate.emails.count == 0 {
            radioNoneOutlet.isEnabled = false
            radioAlertOutlet.isEnabled = false
            radioReportOutlet.isEnabled = false
            radioAlertReportOutlet.isEnabled = false
            return
        }
        guard let map = maps[safe: mapIndex] else { return }
        guard let email = appDelegate.emails[safe: emailIndex] else { return }
        if email.pagerOnly {
            radioNoneOutlet.isEnabled = true
            radioAlertOutlet.isEnabled = true
            radioReportOutlet.isEnabled = false
            radioAlertReportOutlet.isEnabled = false
        } else {
            radioNoneOutlet.isEnabled = true
            radioAlertOutlet.isEnabled = true
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
        guard let email = appDelegate.emails[safe: emailIndex] else { return }
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
