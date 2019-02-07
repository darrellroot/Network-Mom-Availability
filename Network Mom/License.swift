//
//  License.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/5/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import StoreKit
import OpenSSL

enum productIdentifiers: String {
    case oneyear = "net.networkmom.availability.oneyear"
    case monthly = "net.networkmom.availability.monthly"
}

/*enum ReceiptValidationError: Error {
    case receiptNotFound
    case jsonResponseIsNotValid(description: String)
    case notBought
    case expired
}*/

class License: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var products: [String:SKProduct] = [:]

    let productIdentifiers: Set<String> = ["net.networkmom.availability.monthly","net.networkmom.availability.oneyear"]
    private var productsRequest: SKProductsRequest?

    override init() {
        super.init()
        self.requestProducts()
    }
    private func requestProducts() {
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            products[product.productIdentifier] = product
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred:
                break
            case .purchasing:
                break
                
            }
        }
    }
    private func complete(transaction: SKPaymentTransaction) {
        printTransaction(transaction: transaction)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "in-app purchase succeeded"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    private func restore(transaction: SKPaymentTransaction) {
        printTransaction(transaction: transaction)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "in-app restore succeeded"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
/*    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
    }*/
    private func fail(transaction: SKPaymentTransaction) {
        printTransaction(transaction: transaction)
        if let error = transaction.error {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Warning: in-app purchase failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    func printTransaction(transaction: SKPaymentTransaction) {
        print("product identifiers \(transaction.payment.productIdentifier)")
        print("transaction identifiers \(transaction.transactionIdentifier)")
        print("transaction date \(transaction.transactionDate)")
        print("transaction state \(transaction.transactionState.rawValue)")
        if let error = transaction.error {
            print("error \(error.localizedDescription)")
        }
        for download in transaction.downloads {
            print("download identifier \(download.contentIdentifier)")
            print("download length \(download.contentLength)")
            print("download version \(download.contentVersion)")
            print("download transaction")
            print("download state \(download.state)")
            if let url = download.contentURL {
                print("download url \(url)")
            }
            printTransaction(transaction: transaction)
        }
        if let original = transaction.original {
            print("ORIGINAL TRANSACTION")
            printTransaction(transaction: original)
        }
    }
    func decryptReceipt() {
        if let receiptURL = Bundle.main.appStoreReceiptURL,
        let appCertURL = Bundle.main.url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
            let receiptData = NSData(contentsOf: receiptURL),
            let appCertData = NSData(contentsOf: appCertURL) {
            
        }
    }
}
