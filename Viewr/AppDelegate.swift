//
//  AppDelegate.swift
//  Viewr
//
//  Created by Rhianne Price on 15/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa

//
// Entry point of the program.
// Launches a single documwnt window for viewing a PDF File.
// Can have multiple document windowswith independent lecture sets.
//
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Keep references to all the currrently open document windows(document window will keep trak of their own presentation windows)
    var openWindows = Set<NSWindowController>()
    
    // Open a new document window on launch
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        newDocumentWindow(self)
    }
    
    // If the application is reopened, and no windows are open, a new document window should be opened
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            newDocumentWindow(self)
        }
        return flag
    }
    
    // function for opening a single new document window with no PDF open.
    // Triggered by the File > New Lecture Set menu item
    @IBAction func newDocumentWindow(_ sender: Any) {
        let documentWindow = DocumentWindowController()
        openWindows.insert(documentWindow)
        documentWindow.showWindow(sender)
    }
}

