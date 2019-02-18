//
//  LicensePurchaseController.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/5/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import StoreKit
import DLog

class LicensePurchaseController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

    var license: License?
    var sortedCoreLicense: [CoreLicense]?
    let dateFormatter = DateFormatter()
    
    fileprivate enum CellIdentifier: String {
        case Product = "Product"
        case TransactionID = "TransactionID"
        case PurchaseDate = "PurchaseDate"
        case StartDate = "StartDate"
        case EndDate = "EndDate"
    }
    @IBOutlet weak var tableViewOutlet: NSTableView!
    
    @IBOutlet weak var subscribeAnnualOutlet: NSButton!
    
    @IBOutlet weak var currentLicenseOutlet: NSTextField!
    @IBOutlet weak var licensePeriodOutlet: NSTextField!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("LicensePurchaseController")
    }

    
    override func windowDidLoad() {
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        super.windowDidLoad()
        subscribeAnnualOutlet.usesSingleLineMode = false
        updateDisplay()
        /*restoreButton = NSButton(frame: NSRect(x:20, y:20, width:100, height: 20))
        restoreButton.bezelStyle = .roundRect
        restoreButton.title = "Restore In-App Purchases"
        restoreButton.action = #selector(restorePurchasesButton)
        self.window?.contentView?.addSubview(restoreButton)*/
    }
    
    @IBAction func purchaseOneYearLicense(_ sender: NSButton) {
        if let license = license, let product = license.products[productIdentifiers.annual.rawValue] {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    func updateButton(button: NSButton, product: SKProduct) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let localizedPrice = formatter.string(from: product.price) ?? "Error: price unknown"
        
        let localizedTitle: String
        // dealing with problem in apple app store, hope to retire this code
        if product.localizedTitle.count < 1 {
            DLog.log(.license,"Error product.localizedTitle is \(product.localizedTitle) count \(product.localizedTitle.count )")
            localizedTitle = Constants.backupLocalizedProductTitle
        } else {
            localizedTitle = product.localizedTitle
        }
        
        let localizedDescription: String
        if product.localizedDescription.count < 1 {
            DLog.log(.license,"Error product.localizedDescription is \(product.localizedDescription) count \(product.localizedDescription.count )")
            localizedDescription = Constants.backupLocalizedProductDescription
        } else {
            localizedDescription = product.localizedDescription
        }
        // end of app store problem

        let title = """
        \(localizedTitle)
        \(localizedDescription)
        \(localizedPrice)
        """
        button.title = title
        button.sizeToFit()
    }
    public func updateDisplay() {
        guard let license = license else {
            DLog.log(.license,"Unable to access license information in license purchase screen")
            return
        }
        let status = license.licenseStatus
        
        currentLicenseOutlet.stringValue = "Current License Status: \(status.rawValue)"
        currentLicenseOutlet.sizeToFit()
        licensePeriodOutlet.stringValue = "License Period Remaining: \(license.licenseString)"
        licensePeriodOutlet.sizeToFit()

        if let annualProduct = license.products[productIdentifiers.annual.rawValue] {
            updateButton(button: subscribeAnnualOutlet, product: annualProduct)
        }
        tableViewOutlet.sizeToFit()
        tableViewOutlet.reloadData()
    }
    
    @IBAction func restorePurchasesButton(_ sender: NSButton) {
        updateDisplay()
        license?.printLicenses()
        DLog.log(.license,"trying to refresh receipt and restore transactions")
        license?.refreshReceipt()
        //SKPaymentQueue.default().restoreCompletedTransactions()
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let license = license else { return 0 }
        return license.coreLicenses.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier: CellIdentifier
        var text: String
        switch tableColumn {
        case tableViewOutlet.tableColumns[0]:
            cellIdentifier = CellIdentifier.Product
            text = license?.sortedCoreLicenses[safe: row]?.product ?? "Unknown"
            if let alternateText = license?.products[text]?.localizedTitle {
                text = alternateText
            }
            if text.count < 1 {
                text = Constants.backupLocalizedProductTitle
            }
        case tableViewOutlet.tableColumns[1]:
            cellIdentifier = CellIdentifier.PurchaseDate
            let date = license?.sortedCoreLicenses[safe: row]?.purchaseDate
            if let date = date {
                text = dateFormatter.string(from: date)
            } else {
                text = "Unknown"
            }
        case tableViewOutlet.tableColumns[2]:
            cellIdentifier = CellIdentifier.StartDate
            let date = license?.sortedCoreLicenses[safe: row]?.startDate
            if let date = date {
                text = dateFormatter.string(from: date)
            } else {
                text = "Unknown"
            }
        case tableViewOutlet.tableColumns[3]:
            cellIdentifier = CellIdentifier.EndDate
            let date = license?.sortedCoreLicenses[safe: row]?.endDate
            if let date = date {
                text = dateFormatter.string(from: date)
            } else {
                text = "Unknown"
            }
        case tableViewOutlet.tableColumns[4]:
            cellIdentifier = CellIdentifier.TransactionID
            text = license?.sortedCoreLicenses[safe: row]?.transactionIdentifier ?? "Unknown"
        default:
            DLog.log(.license,"Error in license table, unexpected column")
            cellIdentifier = CellIdentifier.Product
            text = "Unknown"
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier.rawValue), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                return cell
            }
            return nil

    }
}
