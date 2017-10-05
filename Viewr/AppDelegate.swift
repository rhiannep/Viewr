//
//  AppDelegate.swift
//  Viewr
//
//  Created by Rhianne Price on 15/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var openWindows = Set<NSWindowController>()
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        newDocumentWindow(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            newDocumentWindow(self)
        }
        return flag
    }

    @IBAction func newDocumentWindow(_ sender: Any) {
        let documentWindow = DocumentWindowController()
        openWindows.insert(documentWindow)
        documentWindow.showWindow(sender)
    }
}

