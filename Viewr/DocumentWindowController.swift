//
//  DocumentWindowController.swift
//  Viewr
//
//  Created by Rhianne Price on 15/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa
import Quartz

// Controller for the main window of the viewer. Coordinates the side bar with the two outline views,
// the pdf view, and the lecture tool bar.
class DocumentWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet weak var bookmarkOutline: BookmarkOutline!
    @IBOutlet weak var bookmarkOutlineView: NSOutlineView!
    
    @IBOutlet weak var lectureOutline: LectureSetModel!
    @IBOutlet weak var lectureOutlineView: NSOutlineView!
    
    @IBOutlet weak var pdfView: PDFView!
    
    @IBOutlet weak var toolBarTitle: NSTextField!
    @IBOutlet weak var toolBar: NSView!

    var openDocuments = 0
    var openDocumentNames = [URL]()
    var bookmarkCount = 0
    
    // The current document in the view
    var selectedDocument : PDFDocument? = nil {
        didSet {
            pdfView.document = selectedDocument
            let name = selectedDocument?.documentURL?.lastPathComponent
            window?.title = "\(name!) (\(openDocuments) open)"
            toolBarTitle.stringValue = name!
            toolBar.isHidden = false
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        lectureOutline?.set(window: self)
        bookmarkOutline?.set(owner: self)
        self.lectureOutlineView.reloadData()
        
        // Observer to change the lecture outline view when the pdf is scrolled.
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentWindowController.pdfViewScolled), name: .PDFViewPageChanged, object: nil)
    }
    
    // convenience initialiser loads the correct view from it's nib file
    convenience init() {
        self.init(windowNibName: NSNib.Name(rawValue: "DocumentWindow"))
    }
    
    // Function to handle the opening of documents
    // triggered by the "+" button at the top of the lecture list
    // The most recently opened document is selected in the outline view.
    // Can open mutiple documents at once.
    @IBAction func openPDF(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = ["pdf"]
        
        openPanel.beginSheetModal(for: self.window!, completionHandler: {(status) in
            if status == NSApplication.ModalResponse.OK {
                for url in openPanel.urls {
                    if var document = PDFDocument(url: url) {
                        if !self.openDocumentNames.contains(url) {
                            self.lectureOutline.append(document)
                            self.openDocumentNames.append(url)
                            self.openDocuments += 1
                            self.selectedDocument = document
                        } else {
                            self.selectedDocument = self.lectureOutline.get(byURL: url)
                            document = self.selectedDocument!
                        }
                        self.lectureOutlineView.reloadData()
                        self.selectedDocument = document
                        self.lectureOutlineView.selectRowIndexes(IndexSet(integer: self.lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
                    }
                }
            }
        })
    }
    
    // change the selcted document in the outline view when the page changes in the pdfview
    @objc func pdfViewScolled(_ notification: NSNotification) {
        let page = pdfView?.currentPage
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: page)), byExtendingSelection: false)
    }
    
    // called when the lecture selction changes in the lecture outline view.
    // scrolls to the appropriate page on the pdfview
    func lectureSelectionDidChange(_ item: Any) {
        if let document = item as? PDFDocument {
            selectedDocument = document
            pdfView.go(to: document.page(at: 0)!)
            toolBarTitle.stringValue = (document.documentURL?.lastPathComponent)!
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
        } else if let page = item as? PDFPage {
            selectedDocument = page.document
            pdfView.go(to: page)
            toolBarTitle.stringValue = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
        } else if let bookmark = item as? Bookmark {
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: bookmark.page)), byExtendingSelection: false)
        }
        lectureOutlineView.scrollRowToVisible(lectureOutlineView.selectedRow)
    }
    
    // Changes the selection on the lecture outline view to the previous item when the "previous" control is hit.
    // The pdfview then changes when the lecture outline delegate is notified.
    @IBAction func goToPreviousOutlineItem(_ sender: Any) {
        let previous = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow - 1)
        if let lecture = previous as? PDFDocument {
            lectureOutlineView.expandItem(lecture)
        }
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.selectedRow - 1), byExtendingSelection: false)
    }
    
    // Changes the selection on the lecture outline view to the next item when the "next" control is hit.
    // The pdfview then changes when the lecture outline delegate is notified.
    @IBAction func goToNextOutlineItem(_ sender: Any) {
        let this = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow)
        if let lecture = this as? PDFDocument {
            lectureOutlineView.expandItem(lecture)
        }
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.selectedRow + 1), byExtendingSelection: false)
    }
    
    // Function to add a new bookmark for the current page in the pdf view to the bookmark model.
    // Handles changes to the bookmark outline view.
    @IBAction func newBookmark(_ sender: Any) {
        if let page = pdfView.currentPage {
            let name = "page \(page.label!), \((page.document?.documentURL?.lastPathComponent)!)"
            let bookmark = Bookmark(name: name, page: page)
            bookmarkOutline.add(bookmark)
            bookmarkOutlineView.reloadData()
            bookmarkOutlineView.selectRowIndexes(IndexSet(integer: bookmarkOutlineView.numberOfRows - 1), byExtendingSelection: false)
            let cellView = bookmarkOutlineView.rowView(atRow: bookmarkOutlineView.selectedRow, makeIfNecessary: true)?.subviews.first
            let label = cellView?.subviews.first(where: {$0.identifier == NSUserInterfaceItemIdentifier(rawValue: "bookmarkName")}) as? NSTextField
            bookmarkCount += 1
            label?.stringValue = "New Bookmark \(bookmarkCount)"
            window?.makeFirstResponder(label)
            bookmarkOutlineView.scrollRowToVisible(bookmarkOutlineView.selectedRow)
        }
    }
}
