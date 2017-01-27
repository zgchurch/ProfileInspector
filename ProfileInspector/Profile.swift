//
//  Document.swift
//  ProfileInspector
//
//  Created by Zachary Church on 12/10/16.
//  Copyright © 2016 Zachary Church. Available under MIT license.
//

import Cocoa
import Security

class SigningCertificate: NSObject {
    var certificate: SecCertificate!
    var name: String? {
        var result: CFString?
        SecCertificateCopyCommonName(certificate, &result)
        
        return result as? String
    }
    
    var serialNumberData: Data? {
        var error: Unmanaged<CFError>?
        let result = SecCertificateCopySerialNumber(certificate, &error) as? Data
        if (error != nil) { print(error!) }
        return result
    }
    
    var serialNumber: String? {
        if let serialNumber = serialNumberData {
            var serial: UInt64 = 0
            (serialNumber as NSData).getBytes(&serial, length: MemoryLayout<UInt64>.size)
            let swapped = serial.bigEndian
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter.string(from: NSNumber.init(value: swapped))
        }
        else {
            return nil
        }
    }
    
    var keychains: String {

        let query: [NSString:Any] = [
            kSecClass: kSecClassCertificate,
            kSecAttrSerialNumber: self.serialNumberData! as NSData,
            kSecReturnAttributes:kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecMatchPolicy: SecPolicyCreateBasicX509()
        ]

        var result: CFTypeRef?
        let errNo = SecItemCopyMatching(query as CFDictionary, &result)
        
        if errNo == errSecItemNotFound {
            return "<not found>"
        }
        else if errNo != 0 {
            print("SecItemCopyMatching: \(errNo)")
            return "<failed to search keychains>"
        }
        else {
            return "available"
        }
        
    }
    
    init(withPEMData data:Data) {
        super.init()
        certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (data as CFData))
    }
}

class Entitlement: NSObject {
    var key: String!
    var value: AnyObject!
    var valueString: String {
        switch value {
        case is String:
            return value as! String
        case is Array<AnyObject>:
            return ((value as! NSArray) as! Array).joined(separator: ", ")
        default:
            return value.description
        }
    }
    
    init(key: String, value: AnyObject) {
        super.init()
        self.key = key
        self.value = value
    }
}

class Profile: NSDocument {
    var rawProfileString: String?
    var profileSigner: SecCertificate?
    var signerSubject: String?
    
    var applicationIdentifier: String?
    var applicationIdentifierPrefix: String?
    var creationDate: Date?
    var expirationDate: Date?
    var platforms: [String]?
    var entitlements: [Entitlement] = []
    var name: String?
    var devices: Array<String>?
    var teamIdentifier: String?
    var teamName:String?
    var ttl: UInt?
    var uuid: String?
    var version: String?

    var signingCertificates = Array<SigningCertificate>()
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        var decoder: CMSDecoder?
        var rawProfileData: CFData?

        var errStatus = CMSDecoderCreate(&decoder)
        if errStatus != noErr { Swift.print("Could not create the decoder"); return }
        
        errStatus = CMSDecoderUpdateMessage(decoder!, (data as NSData).bytes, data.count)
        if errStatus != noErr { Swift.print("Could not set the decoder content"); return }

        errStatus = CMSDecoderFinalizeMessage(decoder!)
        if errStatus != noErr { Swift.print("Could not set the decoder content"); return }

        errStatus = CMSDecoderCopyContent(decoder!, &rawProfileData)
        if errStatus != noErr { Swift.print("Could not open the raw message data: \(errStatus)"); return }
        
        CMSDecoderCopySignerCert(decoder!, 0, &profileSigner)
        if errStatus != noErr { Swift.print("Could not inspect the profile signer: \(errStatus)"); return }
        
        signerSubject = SecCertificateCopySubjectSummary(profileSigner!) as String
        
        var format = PropertyListSerialization.PropertyListFormat.xml
        let plist = try PropertyListSerialization.propertyList(from: rawProfileData! as Data, options: PropertyListSerialization.ReadOptions.init(rawValue: 0), format: &format) as! Dictionary<String, Any>
        
        if let rawProfileData = rawProfileData as? Data {
            rawProfileString = String.init(data: rawProfileData, encoding: .utf8)
        }
        
        applicationIdentifier = plist["AppIDName"] as? String
        applicationIdentifierPrefix = (plist["ApplicationIdentifierPrefix"] as? Array<String>)?.joined(separator: ", ")
        creationDate = plist["CreationDate"] as? Date
        expirationDate = plist["ExpirationDate"] as? Date
        platforms = plist["Platform"] as? Array<String>
        
        let entitlementsDict = plist["Entitlements"] as? Dictionary<String, AnyObject>
        if let entitlementsDict = entitlementsDict {
            for key in entitlementsDict.keys {
                entitlements.append(Entitlement.init(key: key, value: entitlementsDict[key]!))
            }
        }
        
        name = plist["Name"] as? String
        devices = plist["ProvisionedDevices"] as? Array<String>
        teamIdentifier = (plist["TeamIdentifier"] as? Array<String>)?.joined(separator: ", ")
        teamName = plist["TeamName"] as? String
        ttl = plist["TTL"] as? UInt
        uuid = plist["UUID"] as? String

        if let signingPEMs = (plist["DeveloperCertificates"] as? Array<Data>) {
            for pemData in signingPEMs {
                signingCertificates.append(SigningCertificate(withPEMData: pemData))
            }
        }
    }
}

