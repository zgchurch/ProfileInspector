//
//  PrettyProfileViewController.swift
//  ProfileInspector
//
//  Created by Zachary Church on 12/10/16.
//  Copyright © 2016 Zachary Church. Available under MIT license.
//

import Cocoa
import SecurityInterface.SFCertificatePanel

class PrettyProfileViewController: NSViewController {
    @IBOutlet var developerCertificatesArrayController: NSArrayController!
    @IBOutlet var provisionedDevicesArrayController: NSArrayController!
    @IBOutlet var entitlementsArrayController: NSArrayController!
    @IBOutlet var platformsArrayController: NSArrayController!
    @IBOutlet var signerSubject: NSButton!
    @IBOutlet weak var provisionedDevicesTableColumn: NSTableColumn!

    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let document = document as? Profile {
            provisionedDevicesArrayController.content = document.devices
            developerCertificatesArrayController.content = document.signingCertificates
            entitlementsArrayController.content = document.entitlements
            platformsArrayController.content = document.platforms
            signerSubject.title = document.signerSubject!
            
            if let deviceCount = document.devices?.count {
                switch deviceCount {
                    case 0:
                        break
                    case 1:
                        provisionedDevicesTableColumn.title = "Provisioned Devices - 1 device"
                    default:
                        provisionedDevicesTableColumn.title = "Provisioned Devices - \(deviceCount) devices"
                }
            }
            
            let fields = [
                "name",
                "applicationIdentifier",
                "applicationIdentifierPrefix",
                "teamIdentifier",
                "teamName",
                "expirationDate",
                "creationDate",
                "uuid",
            ]
            for field in fields {
                view.subviews.forEach({ (v) in
                    if v.identifier == field {
                        if let v = v as? NSControl {
                            if let value = document.value(forKey: field) {
                                if value is Date {
                                  v.stringValue = formatDate(from: value as! Date)
                                }else{
                                  v.stringValue = (value as AnyObject).description
                                }
                            }
                            else {
                                v.stringValue = ""
                            }
                        }
                    }
                })
            }
        }
    }
    
    func formatDate(from date: Date)->String{
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        
        let dateString = formatter.string(from: date)
        return dateString
    }
    
    func showCertificateSheet(certificates: Array<SecCertificate>) {
        let panel = SFCertificatePanel.shared()
        
        panel?.beginSheet(for: view.window, modalDelegate: nil, didEnd: nil, contextInfo: nil, certificates: certificates, showGroup: true)
    }

    @IBAction func showProfileSignerCertificateSheet(sender: AnyObject?) {
        let profile = document as! Profile
        showCertificateSheet(certificates: [profile.profileSigner!])
    }

    @IBAction func showSigningIdentityCertificateSheet(sender: AnyObject?) {
        if let certificates = developerCertificatesArrayController.selectedObjects as? Array<SigningCertificate> {
                let secCertificates = certificates.map({ (c) -> SecCertificate in
                    return c.certificate
                })
            
                showCertificateSheet(certificates: secCertificates)
        }
    }
}
