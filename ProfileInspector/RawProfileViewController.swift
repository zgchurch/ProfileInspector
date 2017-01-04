//
//  RawProfileViewController.swift
//  ProfileInspector
//
//  Created by Zachary Church on 12/10/16.
//  Copyright © 2016 Zachary Church. Available under MIT license.
//

import Cocoa

class RawProfileViewController: NSViewController {
    @IBOutlet var rawProfileTextView: NSTextView!

    override func viewDidAppear() {
        super.viewDidAppear()
        
        rawProfileTextView.string = (document as? Profile)?.rawProfileString
    }
}
