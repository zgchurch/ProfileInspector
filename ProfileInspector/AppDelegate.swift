//
//  AppDelegate.swift
//  ProfileInspector
//
//  Created by Zachary Church on 12/10/16.
//  Copyright © 2016 Zachary Church. Available under MIT license.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBAction func revealXcodeProvisioningProfiles(sender: AnyObject?) {
        let profileDir = URL.init(fileURLWithPath: "Library/MobileDevice/Provisioning Profiles", relativeTo: FileManager.default.homeDirectoryForCurrentUser)
        NSWorkspace.shared().open(profileDir)
    }
}

