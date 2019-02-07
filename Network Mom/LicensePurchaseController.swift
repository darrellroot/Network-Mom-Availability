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
    @IBOutlet var textViewOutlet: NSTextView!
    @IBOutlet weak var scrollViewOutlet: NSScrollView!

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("LicensePurchaseController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func purchaseOneYearLicense(_ sender: NSButton) {
        if let license = license, let product = license.products[productIdentifiers.oneyear.rawValue] {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    @IBAction func purchaseMonthlySubscription(_ sender: NSButton) {
        if let license = license, let product = license.products[productIdentifiers.monthly.rawValue] {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    @IBAction func checkStuffButton(_ sender: NSButton) {
        if let license = license {
            let products = license.products.values.sorted() { $0.localizedDescription < $1.localizedDescription }
            textViewOutlet.string = ""
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
            }
        }
    }
    @IBAction func restorePurchasesButton(_ sender: NSButton) {
            DLog.log(.userInterface,"trying to restore transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
