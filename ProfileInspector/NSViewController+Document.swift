//
//  NSViewController+Document.swift
//  ProfileInspector
//
//  Created by Zachary Church on 12/10/16.
//  Copyright © 2016 Zachary Church. Available under MIT license.
//

import Cocoa

extension NSViewController {
    var document: NSDocument? {
        if let window = view.window {
            return NSDocumentController.shared().document(for: window)
        }
        else {
            return nil
        }
    }
}
