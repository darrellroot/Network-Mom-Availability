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

class LicensePurchaseController: NSWindowController {

    var license: License?

    @IBOutlet weak var subscribeMonthlyOutlet: NSButton!
    
    @IBOutlet weak var subscribeAnnualOutlet: NSButton!
    
    
    @IBOutlet weak var currentLicenseOutlet: NSTextField!
    @IBOutlet weak var licensePeriodOutlet: NSTextField!
    
    @IBOutlet weak var trialPeriodOutlet: NSTextField!
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("LicensePurchaseController")
    }

    
    override func windowDidLoad() {
        super.windowDidLoad()
        subscribeMonthlyOutlet.usesSingleLineMode = false
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                self.updateDisplay()
            }
        }
    }
    
    @IBAction func purchaseMonthlySubscription(_ sender: NSButton) {
        if let license = license, let product = license.products[productIdentifiers.monthly.rawValue] {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
            DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                self.updateDisplay()
            }
        }
    }
    func updateButton(button: NSButton, product: SKProduct) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let localizedPrice = formatter.string(from: product.price) ?? "Error: price unknown"

        let units = product.subscriptionPeriod?.numberOfUnits
        let unitsString: String
        if let units = units {
            unitsString = String(units)
        } else {
            unitsString = "error unknown quantity"
        }
        let period = product.subscriptionPeriod?.unit.string ?? "Error: unknown period"
        let title = """
        \(product.localizedTitle)
        \(product.localizedDescription)
        \(unitsString) \(period)
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
        let status = license.getLicenseStatus
        
        currentLicenseOutlet.stringValue = "Current License Status: \(status.rawValue)"
        currentLicenseOutlet.sizeToFit()
        licensePeriodOutlet.stringValue = "License Period Remaining: \(license.licenseString)"
        licensePeriodOutlet.sizeToFit()
        trialPeriodOutlet.stringValue = "Trial Period Remaining: \(license.trialString)"
        trialPeriodOutlet.sizeToFit()
        if let monthlyProduct = license.products[productIdentifiers.monthly.rawValue] {
            updateButton(button: subscribeMonthlyOutlet, product: monthlyProduct)
        }
        if let annualProduct = license.products[productIdentifiers.annual.rawValue] {
            updateButton(button: subscribeAnnualOutlet, product: annualProduct)
        }
            //let attributedTitle = NSAttributedString(string: title)
            //subscribeMonthlyOutlet.attributedTitle = attributedTitle
            //subscribeMonthlyOutlet.sizeToFit()
    }
    /*@IBAction func checkStuffButton(_ sender: NSButton) {
        if let license = license {
            let products = license.products.values.sorted() { $0.localizedDescription < $1.localizedDescription }
            textViewOutlet.string = ""
            license.decryptReceiptSwifty()
            for product in products {
                textViewOutlet.string += "\(product.productIdentifier)\n"
                textViewOutlet.string += "\(product.localizedDescription)\n"
                textViewOutlet.string += "\(product.localizedTitle)\n"
                let formatter = NumberFormatter()
                formatter.locale = product.priceLocale
                formatter.numberStyle = .currency
                if let localizedPrice = formatter.string(from: product.price) {
                    textViewOutlet.string += "\(localizedPrice)\n"
                }
                textViewOutlet.string += "\n"
                textViewOutlet.string += license.fullLicenseStatus
            }
        }
        //let validator = ReceiptValidator()
        //let result = validator.validateReceipt()
        //textViewOutlet.string += "receipt validationr result \(result)"
    }*/
    @IBAction func restorePurchasesButton(_ sender: NSButton) {
        updateDisplay()
        DLog.log(.license,"trying to restore transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.updateDisplay()
        }
    }
}
