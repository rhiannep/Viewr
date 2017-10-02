//
//  PresentationWindowController.swift
//  Viewr
//
//  Created by Rhianne Price on 1/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa
import Quartz

class PresentationWindowController: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var pdfView: PDFView!
    
    var ownerWindow: DocumentWindowController?
    
    convenience init(owner: DocumentWindowController) {
        self.init(windowNibName: NSNib.Name(rawValue: "PresentationWindow"))
        ownerWindow = owner
    }
    
    func update(_ page: PDFPage?) {
        if let newPage = page {
            pdfView.document = newPage.document
            pdfView.go(to: newPage)
        } else {
            pdfView.document = nil
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "Present"

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func windowWillClose(_ notification: Notification) {
        ownerWindow?.presentationWindows.remove(self)
        dump(ownerWindow?.presentationWindows)
    }
}
