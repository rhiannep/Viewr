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
    
    @IBAction func nextSearcher(_ sender: NSSegmentedControl) {
        dump(sender)
    }
    
    @IBOutlet weak var pdfView: PDFView!
    
    var ownerWindow: DocumentWindowController?
    
    convenience init(owner: DocumentWindowController) {
        self.init(windowNibName: NSNib.Name(rawValue: "PresentationWindow"))
        ownerWindow = owner
    }
    
    func update(_ page: PDFPage?) {
        if let newPage = page {
            window?.title = "Presenting \(newPage.document?.documentURL?.lastPathComponent ?? "") page \(newPage.label ?? "")"
            // make a new single page document so that the pdf can't be scrolled in the presentation window
            pdfView.document = PDFDocument(data: newPage.dataRepresentation)
        } else {
            pdfView.document = nil
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "Present"
        if let screen = NSScreen.main {
            window?.setFrame(screen.visibleFrame, display: true, animate: true)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        ownerWindow?.presentationWindows.remove(self)
    }
}
