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

    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let document = document as? Profile {
            provisionedDevicesArrayController.content = document.devices
            developerCertificatesArrayController.content = document.signingCertificates
            entitlementsArrayController.content = document.entitlements
            platformsArrayController.content = document.platforms
            signerSubject.title = document.signerSubject!
            
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
                                v.stringValue = (value as AnyObject).description
                            }
                        }
                    }
                })
            }
        }
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
