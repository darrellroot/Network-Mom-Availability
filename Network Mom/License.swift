//
//  License.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/12/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import DLog
import StoreKit

enum productIdentifiers: String {
    case annual = "net.networkmom.availability.v1.oneyear"
    //case annual = "net.networkmom.availability.annual"
    //case monthly = "net.networkmom.availability.monthly"
}
//    static let licenseDuration = [Constants.annual:300]

enum LicenseStatus: String {
    case licensed
    case expired
    case unknown
}
class License: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    let dateFormatter = DateFormatter()
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var managedContext: NSManagedObjectContext!
    var coreLicenses: [CoreLicense] = []
    var sortedCoreLicenses: [CoreLicense] = []

    var products: [String:SKProduct] = [:]
    private var productsRequest: SKProductsRequest?
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    
    var lastLicenseStatus: LicenseStatus = .unknown
    var licenseStatus: LicenseStatus {
        guard let lastLicenseDate = lastLicenseDate else {
            if lastLicenseStatus != .unknown {
                DLog.log(.license,"Error: license status changed to unknown")
            }
            lastLicenseStatus = .unknown
            return .unknown
        }
        if Date() < lastLicenseDate {
            lastLicenseStatus = .licensed
            return .licensed
        } else {
            if lastLicenseStatus == .licensed {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Warning: Network Mom License Expired"
                    alert.informativeText = "Check the License Purchase/Status menu"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
            lastLicenseStatus = .expired
            return .expired
        }
    }
    var licenseString: String {
        switch self.licenseStatus {
        case .expired:
            return "None"
        case .unknown:
            return "Unknown"
        case .licensed:
            guard let lastLicenseDate = lastLicenseDate else { return "Unknown" }
            let timeInterval = lastLicenseDate.timeIntervalSinceNow
            let timeString = time2String(seconds: timeInterval)
            return timeString
        }
        // should never get here
    }
    func time2String(seconds: Double) -> String {
        if seconds > 3600 * 24 {
            let days = Int(seconds) / (3600 * 24)
            return "\(days) days"
        } else if seconds > 3600.0 {
            let hours = Int(seconds) / (3600)
            return "\(hours) hours"
        } else if seconds > 0.0 {
            return "< 1 hour"
        } else {
            return "None"
        }
    }

    var lastLicenseString: String {
        guard let lastLicenseDate = lastLicenseDate else {
            return "Unknown"
        }
        let dateString = dateFormatter.string(from: lastLicenseDate)
        return dateString
    }
    var lastLicenseDate: Date?

    override init() {
        managedContext = appDelegate.managedContext
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        super.init()
        let request = NSFetchRequest<CoreLicense>(entityName: Constants.CoreLicense)
        if let coreLicenseArray = try? managedContext.fetch(request) {
            DLog.log(.license,"Found core license data: \(coreLicenseArray.count) entries")
            DLog.log(.dataIntegrity,"Found core license data")
            self.coreLicenses = coreLicenseArray
            if self.coreLicenses.count == 0 {
                makeGraceLicense()
            }
        } else {
            makeGraceLicense()
        }
        requestProducts()
        analyzeLicense()
    }
    private func makeGraceLicense() {
        DLog.log(.license,"No license data found, acting as new install")
        DLog.log(.dataIntegrity,"No license data found, acting as new install")
        let endDate = Date() + Constants.gracePeriodDuration
        let graceLicense =  CoreLicense(context: managedContext, product: Constants.GracePeriod, purchaseDate: Date(), startDate: Date(), endDate: endDate, transactionIdentifier: Constants.gracePeriodTransaction)
        coreLicenses.append(graceLicense)
    }
    public func refreshReceipt() {
        receiptRefreshRequest?.cancel()
        receiptRefreshRequest = SKReceiptRefreshRequest()
        receiptRefreshRequest?.delegate = self
        receiptRefreshRequest?.start()
    }
    func requestDidFinish(_ request: SKRequest) {
        DLog.log(.license,"Receipt refresh request finished")
        getLicensesFromReceipt()
        //printLicenses()
        analyzeLicense()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    private func requestProducts() {
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: [productIdentifiers.annual.rawValue])
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            DLog.log(.license,"Got product response for product \(product.productIdentifier)")
            products[product.productIdentifier] = product
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                //fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    private func restore(transaction: SKPaymentTransaction) {
        DLog.log(.license,"Received Restore")
        processTransaction(transaction: transaction)
    }
    private func complete(transaction: SKPaymentTransaction) {
        DLog.log(.license,"Transaction complete")
        processTransaction(transaction: transaction)
    }
    func transactionNotLicensed(transactionIdentifier: String) -> Bool {
        return !transactionAlreadyLicensed(transactionIdentifier: transactionIdentifier)
    }
    func transactionAlreadyLicensed(transactionIdentifier: String) -> Bool {
        for license in coreLicenses {
            if transactionIdentifier == license.transactionIdentifier {
                return true
            }
        }
        return false
    }
    
    private func processTransaction(transaction: SKPaymentTransaction) {
        printTransaction(transaction: transaction)
        let productIdentifier = transaction.payment.productIdentifier
        guard let transactionIdentifier = transaction.transactionIdentifier else {
            DLog.log(.license,"Error: in process transaction but no transaction identifier")
            return
        }
        let transactionDate = transaction.transactionDate ?? Date()
        
        if transactionAlreadyLicensed(transactionIdentifier: transactionIdentifier) {
            DLog.log(.license,"Transaction ID \(transactionIdentifier) already in core data, finishing transaction")
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        // Now we have a new transaction to enter
        switch productIdentifier {
        case productIdentifiers.annual.rawValue:
            let newLicense =  CoreLicense(context: managedContext, product: productIdentifier, purchaseDate: transactionDate, startDate: Date(), endDate: nil, transactionIdentifier: transactionIdentifier)
            coreLicenses.append(newLicense)
            if saveLicenses() {
                DLog.log(.license,"transaction processed and license saved, finishing transaction")
                SKPaymentQueue.default().finishTransaction(transaction)
            }
            analyzeLicense()
        default:
            DLog.log(.license,"Error: unknown product identifier \(productIdentifier)")
        }
    }
    
    private func saveLicenses() -> Bool {
        do {
            try managedContext.save()
        } catch {
            DLog.log(.license,"Error: failed to save core data license \(error.localizedDescription)")
            return false
        }
        return true
    }
    private func printTransaction(transaction: SKPaymentTransaction) {
        DLog.log(.license,"\nPRINTING TRANSACTION")
        DLog.log(.license,"product identifiers \(transaction.payment.productIdentifier)")
        DLog.log(.license,"transaction identifiers \(String(describing: transaction.transactionIdentifier))")
        DLog.log(.license,"transaction date \(String(describing: transaction.transactionDate))")
        DLog.log(.license,"transaction state \(transaction.transactionState.rawValue)")
        DLog.log(.license,"END PRINTING TRANSACTION\n")
    }
    public func printLicenses() {
        DLog.log(.license,"Printing \(coreLicenses.count) licenses")
        for license in coreLicenses {
            DLog.log(.license,"\(license.product) \(license.transactionIdentifier) \(license.purchaseDate) \(license.startDate) \(license.endDate)")
        }
        DLog.log(.license,"trying to get and print receipt")
        guard let receipt = getReceipt() else {
            DLog.log(.license,"unable to get receipt")
            return
        }
        printReceipt(receipt)
    }
    
    func analyzeLicense() {
        DLog.log(.license,"Started analyze license")
        self.sortedCoreLicenses = self.coreLicenses.sorted() {$0.purchaseDate < $1.purchaseDate }
        for loop in 0 ..< self.sortedCoreLicenses.count {
            let newStartDate: Date
            if loop == 0 {
                if self.sortedCoreLicenses[safe: loop]?.purchaseDate == nil {
                    DLog.log(.license,"License Error: invalid purchase date in first license\n")
                }
                newStartDate = self.sortedCoreLicenses[safe: loop]?.purchaseDate ?? Date()
                self.sortedCoreLicenses[safe: loop]?.startDate = newStartDate
            } else {
                let priorEndDate = self.sortedCoreLicenses[safe: loop-1]?.endDate ?? Date.distantPast
                let currentPurchaseDate = self.sortedCoreLicenses[safe: loop]?.purchaseDate ?? Date.distantPast
                newStartDate = max(priorEndDate,currentPurchaseDate)
                self.sortedCoreLicenses[safe: loop]?.startDate = newStartDate
            }
            let licenseDuration: TimeInterval
            switch self.sortedCoreLicenses[safe: loop]?.product {
            case productIdentifiers.annual.rawValue:
                licenseDuration = Constants.annualLicenseDuration
            case Constants.GracePeriod:
                licenseDuration = Constants.gracePeriodDuration
            default:
                DLog.log(.license,"Unknown license product detected \(String(describing: self.sortedCoreLicenses[safe: loop]?.product))")
                licenseDuration = 0.0
            }
            self.sortedCoreLicenses[safe: loop]?.endDate = newStartDate + licenseDuration
        }
        if let lastDate = self.sortedCoreLicenses.last?.endDate {
            self.lastLicenseDate = lastDate
        } else {
            DLog.log(.license,"License error: unable to determine last license date")
            self.lastLicenseDate = Date().addingTimeInterval(86400)
        }
        DLog.log(.license,"Last License Date \(String(describing: self.lastLicenseDate))")
        let _ = saveLicenses()
        DispatchQueue.main.async {
            self.appDelegate.licensePurchaseController?.updateDisplay()
        }
    }
    
    private func getLicensesFromReceipt() {
        guard let parsedReceipt = getReceipt() else { return }

        for purchase in parsedReceipt.inAppPurchaseReceipts ?? [] {
            if let transactionIdentifier = purchase.transactionIdentifier, transactionNotLicensed(transactionIdentifier: transactionIdentifier), let purchaseDate = purchase.purchaseDate, let product = purchase.productIdentifier {
                guard product == productIdentifiers.annual.rawValue else {
                    DLog.log(.license,"Invalid product identifier \(product) found")
                    return
                }
                let newLicense = CoreLicense(context: managedContext, product: product, purchaseDate: purchaseDate, startDate: purchaseDate, endDate: nil, transactionIdentifier: transactionIdentifier)
                coreLicenses.append(newLicense)
                DLog.log(.license,"Activated new license ID")
            }
        }
    }
    private func printReceipt(_ receipt: ParsedReceipt) {
        DLog.log(.license,"PRINTING RECEIPT")
        DLog.log(.license,"bundle id \(String(describing: receipt.bundleIdentifier)) receiptCreationDate \(String(describing: receipt.receiptCreationDate))")
        for inAppPurchase in receipt.inAppPurchaseReceipts ?? [] {
            DLog.log(.license,"product \(inAppPurchase.productIdentifier ?? "unknown") transactionID \(inAppPurchase.transactionIdentifier ?? "unknown") originalTransactionID \(inAppPurchase.originalTransactionIdentifier ?? "unknown") purchaseDate \(String(describing: inAppPurchase.purchaseDate))")
        }
    }
    
    private func getReceipt() -> ParsedReceipt? {
        DLog.log(.license,"Trying to analyze receipt")
        let receiptLoader = ReceiptLoader()
        let receiptData: Data
        do {
            receiptData = try receiptLoader.loadReceipt()
        } catch {
            DLog.log(.license,"Unable to load in app purchase receipt")
            return nil
        }
        
        let receiptExtractor = ReceiptExtractor()
        guard let receiptContainer: UnsafeMutablePointer<PKCS7> = receiptExtractor.loadReceipt() else {
            DLog.log(.license,"Unable to extract in app purchase receipt")
            return nil
        }
        let receiptParser = ReceiptParser()
        var parsedReceipt: ParsedReceipt?
        do {
            parsedReceipt = try receiptParser.parse(receiptContainer)
        } catch {
            DLog.log(.license,"Unable to parse in app purcase receipt")
            return nil
        }
        return parsedReceipt
    }
    private func loadReceipt() -> UnsafeMutablePointer<PKCS7>? {
        // Load the receipt into a Data object
        guard
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptUrl)
            else {
                //receiptStatus = .noReceiptPresent
                return nil
        }
        let receiptBIO = BIO_new(BIO_s_mem())
        let receiptBytes: [UInt8] = .init(receiptData)
        BIO_write(receiptBIO, receiptBytes, Int32(receiptData.count))
        // 2
        let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
        BIO_free(receiptBIO)
        // 3
        guard receiptPKCS7 != nil else {
            //receiptStatus = .unknownReceiptFormat
            return nil
        }
        // Check that the container has a signature
        guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
            //receiptStatus = .invalidPKCS7Signature
            return nil
        }
        
        // Check that the container contains data
        let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
        guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
            //receiptStatus = .invalidPKCS7Type
            return nil
        }
        return receiptPKCS7
    }

    
    private func validateSigning(_ receipt: UnsafeMutablePointer<PKCS7>?) -> Bool {
        guard
            let rootCertUrl = Bundle.main
                .url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
            let rootCertData = try? Data(contentsOf: rootCertUrl)
            else {
                //receiptStatus = .invalidAppleRootCertificate
                return false
        }
        
        let rootCertBio = BIO_new(BIO_s_mem())
        let rootCertBytes: [UInt8] = .init(rootCertData)
        BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
        let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
        BIO_free(rootCertBio)
        // 1
        let store = X509_STORE_new()
        X509_STORE_add_cert(store, rootCertX509)
        
        // 2
        OPENSSL_init_crypto(UInt64(OPENSSL_INIT_ADD_ALL_DIGESTS), nil)
        
        // 3
        let verificationResult = PKCS7_verify(receipt, nil, store, nil, nil, 0)
        guard verificationResult == 1  else {
            //receiptStatus = .failedAppleSignature
            return false
        }
        
        return true
    }

    
    private func validateSigning2(_ receipt: UnsafeMutablePointer<PKCS7>?) -> Bool {
        guard
            let rootCertUrl = Bundle.main
                .url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
            let rootCertData = try? Data(contentsOf: rootCertUrl)
            else {
                //receiptStatus = .invalidAppleRootCertificate
                return false
        }
        
        let rootCertBio = BIO_new(BIO_s_mem())
        let rootCertBytes: [UInt8] = .init(rootCertData)
        BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
        let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
        BIO_free(rootCertBio)
        // 1
        let store = X509_STORE_new()
        X509_STORE_add_cert(store, rootCertX509)
        
        // 2
        
        // 3
        let verificationResult = PKCS7_verify(receipt, nil, store, nil, nil, 0)
        guard verificationResult == 1  else {
            //receiptStatus = .failedAppleSignature
            return false
        }
        return true
    }

}
