//
//  PresentationWindowController.swift
//  Viewr
//
//  Created by Rhianne Price on 1/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa
import Quartz

//
// Controller for a window which shows a single PDF Page that is a mirror of the page showed by it's owner.
// A DocumentWindow can own multiple PresentationWindows at once.
//
class PresentationWindowController: NSWindowController, NSWindowDelegate {
    
    // PDF View for this window
    @IBOutlet weak var pdfView: PDFView!
    
    // This presetation windows document window, the one to be mirrored.
    var ownerWindow: DocumentWindowController?
    
    // Initialiser to load the correct nib, and set the windows document window.
    convenience init(owner: DocumentWindowController) {
        self.init(windowNibName: "PresentationWindow")
        ownerWindow = owner
    }
    
    //When the window loads, make it full screen
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Make presentation window full screen
        if let screen = NSScreen.main() {
            window?.setFrame(screen.visibleFrame, display: true, animate: true)
        }
    }
    
    // Function to update the page displayed in this windows PDF View. This is called whenever the owning DOcumnet window's page changes.
    func update(_ page: PDFPage?) {
        if let newPage = page {
            // Update the window title according to the new page
            window?.title = "Presenting \(newPage.document?.documentURL?.lastPathComponent ?? "") page \(newPage.label ?? "")"
            // make a new single page document so that the pdf can't be scrolled in the presentation window
            pdfView.document = PDFDocument(data: newPage.dataRepresentation)
        } else {
            // If the owner window closes all documents, stay open but show nothing
            window?.title = "No lectures open"
            pdfView.document = nil
        }
    }
    

    // Take care of bookkeeping in the owner window when thi window is closed.
    func windowWillClose(_ notification: Notification) {
        ownerWindow?.presentationWindows.remove(self)
    }
}
