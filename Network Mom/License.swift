//
//  License.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 2/5/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Cocoa
import StoreKit
import DLog

enum productIdentifiers: String {
    case annual = "net.networkmom.availability.annual"
    case monthly = "net.networkmom.availability.monthly"
}


/*enum ReceiptValidationError: Error {
    case receiptNotFound
    case jsonResponseIsNotValid(description: String)
    case notBought
    case expired
}*/

enum LicenseStatus: String {
    case licensed
    case trial
    case expired
    case unknown
}

class License: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
//    var receipt: Receipt?
//    var receiptStatus: ReceiptStatus?
    let dateFormatter = DateFormatter()
    
    var coreLicense: CoreLicense
    var newInstall: Bool //set to true if first install until we get license and install history, then set to false
    var lastLicenseDate: Date {
        get {
            return coreLicense.lastLicenseDate as Date? ?? Date.distantPast
        }
        set {
            coreLicense.lastLicenseDate = newValue as NSDate
        }
    }
    var firstInstallDate: Date {
        get {
            return coreLicense.firstInstallDate as Date? ?? Date()
        }
        set {
            coreLicense.firstInstallDate = newValue as NSDate
        }
    }
    let trialSecondsMax = 3600.0 * 24.0 * 30.0
    private(set) var trialSeconds: Double {
        get {
            return coreLicense.trialSeconds
        }
        set {
            coreLicense.trialSeconds = newValue
        }
    }
    public var trialString: String {
        if trialSeconds > 3600 * 24 {
            let trialDays = Int(trialSeconds) / (3600 * 24)
            return "\(trialDays) days"
        } else if trialSeconds > 3600.0 {
            let trialHours = Int(trialSeconds) / (3600)
            return "\(trialHours) hours"
        } else if trialSeconds > 0.0 {
            return "< 1 hour"
        } else {
            return "None"
        }
    }

    public var licenseSeconds: Double {
        let timeLeft = lastLicenseDate.timeIntervalSince(Date())
        if timeLeft < 0 {
            return 0.0
        } else {
            return timeLeft
        }
    }
    public var licenseString: String {
        let licenseSeconds = self.licenseSeconds
        if licenseSeconds > 3600 * 24 {
            let licenseDays = Int(licenseSeconds) / (3600 * 24)
            return "\(licenseDays) days"
        } else if licenseSeconds > 3600.0 {
            let licenseHours = Int(licenseSeconds) / (3600)
            return "\(licenseHours) hours"
        } else if licenseSeconds > 0.0 {
            return "< 1 hour"
        } else {
            return "None"
        }
    }
    var lastLicenseString: String {
        return dateFormatter.string(from:lastLicenseDate)
    }
    var firstInstallString: String {
        return dateFormatter.string(from:firstInstallDate)
    }
    var fullLicenseStatus: String {
        return """
First Install Date: \(firstInstallString)
License In Effect Until: \(lastLicenseString)
Trial Period Seconds Remaining: \(trialSeconds)
License Status \(getLicenseStatus.rawValue)
"""
    }
    private var priorLicenseStatus: LicenseStatus?
    
    var getLicenseStatus: LicenseStatus {
        let date = Date()
        if date < self.lastLicenseDate {
            priorLicenseStatus = .licensed
            return .licensed
        } else if (trialSeconds) > 0 {
            if priorLicenseStatus != .trial {
                DLog.log(.userInterface,"License status just changed: trying to restore transactions")
                SKPaymentQueue.default().restoreCompletedTransactions()
                priorLicenseStatus = .trial
                DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                    if self.getLicenseStatus == .trial {
                        let alert = NSAlert()
                        alert.messageText = "Warning: Network Mom License Expired, Trial Period Activated"
                        alert.informativeText = "Check the License Purchase/Status menu"
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
            priorLicenseStatus = .trial
            return .trial
        } else {
            if priorLicenseStatus != .expired {
                DLog.log(.userInterface,"License status just changed: trying to restore transactions")
                SKPaymentQueue.default().restoreCompletedTransactions()
                priorLicenseStatus = .expired
                DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                    if self.getLicenseStatus == .expired {
                        let alert = NSAlert()
                        alert.messageText = "Alert: Network Mom License Expired, Trial Expired"
                        alert.informativeText = "All monitoring will cease until a license is purchased"
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
            priorLicenseStatus = .expired
            return .expired
        }
    }
    var products: [String:SKProduct] = [:]

    let productIdentifiers: Set<String> = ["net.networkmom.availability.monthly","net.networkmom.availability.annual"]
    private var productsRequest: SKProductsRequest?

    override init() {
        fatalError("should not get to this init")
        super.init()
        //self.requestProducts()
    }
    public func addTrialHour() {
        // we should only execute this once a day, run by a timer in appDelegate
        if self.getLicenseStatus == .licensed {
            if trialSeconds < trialSecondsMax {
                trialSeconds = trialSeconds + 3600.0
            }
            if trialSeconds > trialSecondsMax {
                trialSeconds = trialSecondsMax
            }
        }
    }
    init(coreLicense: CoreLicense, newInstall: Bool = false) {
        self.coreLicense = coreLicense
        self.newInstall = newInstall
        super.init()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        if newInstall {
            DLog.log(.userInterface,"trying to restore transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
        }
        self.requestProducts()
    }
    public func useTrial(seconds: Double) {
        self.trialSeconds = self.trialSeconds - seconds
        if self.trialSeconds < 0 {
            self.trialSeconds = 0
        }
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
        let success = decryptReceiptSwifty()
        printTransaction(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
        
        /*DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "in-app purchase succeeded"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }*/
    }
    private func restore(transaction: SKPaymentTransaction) {
        let success = decryptReceiptSwifty()
        printTransaction(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)

        /*DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "in-app restore succeeded"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }*/
    }
/*    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
    }*/
    private func fail(transaction: SKPaymentTransaction) {
        printTransaction(transaction: transaction)
        if let error = transaction.error {
            /*DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Warning: in-app purchase failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }*/
        }
        SKPaymentQueue.default().finishTransaction(transaction)

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
/*    func decryptReceiptWenderlich() {
        receipt = Receipt()
        if let receiptStatus = receipt?.receiptStatus {
            DLog.log(.userInterface,"receipt status \(receiptStatus.rawValue)")
        }
        guard receiptStatus == .validationSuccess else {
            return
        }
        DLog.log(.userInterface,"Bundle Identifier: \(receipt!.bundleIdString!)")
        DLog.log(.userInterface,"Bundle Version: \(receipt!.bundleVersionString!)")
        let originalAppVersion: String
        if let originalVersion = receipt?.originalAppVersion {
            originalAppVersion = "Original Version: \(originalVersion)"
        } else {
            originalAppVersion = "Not Provided"
        }
        DLog.log(.userInterface,"original app version \(originalAppVersion)")
        let expirationDate: String
        if let receiptExpirationDate = receipt?.expirationDate {
            expirationDate = "Expiration Date: \(receiptExpirationDate)"
        } else {
            expirationDate = "Not Provided."
        }
        DLog.log(.userInterface,"expirationDate \(expirationDate)")
        let receiptCreationDate: String
        if let receiptCreation = receipt?.receiptCreationDate {
            receiptCreationDate = "Receipt Creation Date: \(receiptCreation)"
        } else {
            receiptCreationDate = "Not Provided."
        }
        DLog.log(.userInterface,"receipt creation Date \(receiptCreationDate)")
    }
 */
    func invalidReceipt() {
        DLog.log(.userInterface,"Invalid App Store receipt detected")
    }
    func decryptReceiptSwifty() -> Bool {
        DLog.log(.userInterface,"Trying to analyze receipt")
        let receiptLoader = ReceiptLoader()
        let receiptData: Data
        do {
            receiptData = try receiptLoader.loadReceipt()
        } catch {
            DLog.log(.userInterface,"Unable to load in app purchase receipt")
            invalidReceipt()
            return false
        }
        
        let receiptExtractor = ReceiptExtractor()
        
        guard let receiptContainer: UnsafeMutablePointer<PKCS7> = receiptExtractor.loadReceipt() else {
            DLog.log(.userInterface,"Unable to extract in app purchase receipt")
            invalidReceipt()
            return false
        }
        
        let receiptParser = ReceiptParser()
        var parsedReceipt: ParsedReceipt?
        do {
            parsedReceipt = try receiptParser.parse(receiptContainer)
        } catch {
            DLog.log(.userInterface,"Unable to parse in app purcase receipt")
            invalidReceipt()
            return false
        }
        if let parsedReceipt = parsedReceipt, let receiptCreationDate = parsedReceipt.receiptCreationDate {
            if receiptCreationDate < self.firstInstallDate {
                if let receiptCreationDate = parsedReceipt.receiptCreationDate {
                    self.firstInstallDate = receiptCreationDate
                    DLog.log(.userInterface,"set first install date to \(String(describing: parsedReceipt.receiptCreationDate)) per parsed receipt creation date")
                }
            }
            for receipt in parsedReceipt.inAppPurchaseReceipts ?? [] {
                DLog.log(.userInterface,"receipt type \(String(describing: receipt.productIdentifier)) expiration \(String(describing: receipt.subscriptionExpirationDate))")
                if let originalPurchaseDate = receipt.originalPurchaseDate, originalPurchaseDate < self.firstInstallDate {
                    DLog.log(.userInterface,"set first install date to \(String(describing: parsedReceipt.receiptCreationDate)) per parsed receipt creation date")
                    self.firstInstallDate = originalPurchaseDate
                }
                if let subscriptionExpirationDate = receipt.subscriptionExpirationDate {
                    //if let lastLicenseDate = lastLicenseDate {
                        if subscriptionExpirationDate > lastLicenseDate {
                            self.lastLicenseDate = subscriptionExpirationDate
                            let newDateString = dateFormatter.string(from: subscriptionExpirationDate)
                            DLog.log(.userInterface,"updated last license date to \(newDateString)")
                        }
/*                    } else {
                        self.lastLicenseDate = subscriptionExpirationDate
                        DLog.log(.userInterface,"initially set last license date to \(dateFormatter.string(from: subscriptionExpirationDate))")
                    }*/
                }
            }
        }
        if newInstall {
            calculateTrialSeconds(testOnly: false)
        } else {
            calculateTrialSeconds(testOnly: true)
        }
        let receiptSignatureValidator = ReceiptSignatureValidator()
        
        do {
            try receiptSignatureValidator.checkSignaturePresence(receiptContainer)
        } catch {
            DLog.log(.userInterface,"receipt signature presence error \(error.localizedDescription)")
        }
        do {
            try receiptSignatureValidator.checkSignatureAuthenticity(receiptContainer)
        } catch {
            DLog.log(.userInterface,"receipt signature authenticity error \(error.localizedDescription)")
        }
        let validated = validateSigning(receiptContainer)
        DLog.log(.userInterface,"Ray Wenderlich validation \(validated)")
        let validated2 = validateSigning2(receiptContainer)
        DLog.log(.userInterface,"swifty validation \(validated2)")
        return true
    }
    private func calculateTrialSeconds(testOnly: Bool) {
        var candidateTrialSeconds: Double
        let timeSinceFirstInstall = Date().timeIntervalSince(self.firstInstallDate)
        let timeSinceLastLicense = Date().timeIntervalSince(self.lastLicenseDate)
        if timeSinceLastLicense < 0 {
            candidateTrialSeconds = Defaults.trialPeriodSeconds
        } else if timeSinceLastLicense < Defaults.trialPeriodSeconds {
            candidateTrialSeconds = Defaults.trialPeriodSeconds - timeSinceLastLicense
        } else if timeSinceFirstInstall < Defaults.trialPeriodSeconds {
            candidateTrialSeconds = Defaults.trialPeriodSeconds - timeSinceFirstInstall
        } else {
            candidateTrialSeconds = 0
        }
        print("""
trial seconds calculation test only \(testOnly)
timeSinceFirstInstall \(timeSinceFirstInstall)
timeSinceLastLicense \(timeSinceLastLicense)
candidateTrialSeconds \(candidateTrialSeconds)
""")
        if testOnly {
            //do nothing for real
            return
        }
        if candidateTrialSeconds > Defaults.trialPeriodSeconds {
            //should not get here
            self.trialSeconds = Defaults.trialPeriodSeconds
        } else {
            self.trialSeconds = candidateTrialSeconds
        }
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
