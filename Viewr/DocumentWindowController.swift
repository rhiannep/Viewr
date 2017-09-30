//
//  DocumentWindowController.swift
//  Viewr
//
//  Created by Rhianne Price on 15/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa
import Quartz

class DocumentWindowController: NSWindowController, NSWindowDelegate {
    

    @IBOutlet weak var bookmarkOutline: BookmarkOutline!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var toolBarTitle: NSTextField!
    @IBOutlet weak var toolBar: NSView!
    @IBOutlet weak var lectureOutline: LectureSetOutline!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var bookmarkOutlineView: NSOutlineView!
    
    var openDocuments = 0
    var openDocumentNames = [URL]()
    var bookmarkCount = 0
    
    
    convenience init() {
        self.init(windowNibName: NSNib.Name(rawValue: "DocumentWindow"))
    }
    


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
                        self.outlineView.reloadData()
                        self.selectedDocument = document
                        self.outlineView.selectRowIndexes(IndexSet(integer: self.outlineView.row(forItem: document)), byExtendingSelection: false)
                    }
                }
            }
        })
    }
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
        self.outlineView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentWindowController.pdfViewScolled), name: .PDFViewPageChanged, object: nil)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @objc func pdfViewScolled(_ notification: NSNotification) {
        let page = pdfView?.currentPage
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: page)), byExtendingSelection: false)
    }
    
    func lectureSelectionDidChange(_ item: Any) {
        if let document = item as? PDFDocument {
            selectedDocument = document
            pdfView.go(to: document.page(at: 0)!)
            toolBarTitle.stringValue = (document.documentURL?.lastPathComponent)!
        } else if let page = item as? PDFPage {
            selectedDocument = page.document
            pdfView.go(to: page)
            toolBarTitle.stringValue = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
        } else if let bookmark = item as? Bookmark {
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: bookmark.page)), byExtendingSelection: false)
        }
        outlineView.scrollRowToVisible(outlineView.selectedRow)
    }
    
    @IBAction func goToPreviousOutlineItem(_ sender: Any) {
        let previous = outlineView.item(atRow: outlineView.selectedRow - 1)
        if let lecture = previous as? PDFDocument {
            outlineView.expandItem(lecture)
        }
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.selectedRow - 1), byExtendingSelection: false)
    }
    
    @IBAction func goToNextOutlineItem(_ sender: Any) {
        let this = outlineView.item(atRow: outlineView.selectedRow)
        if let lecture = this as? PDFDocument {
            outlineView.expandItem(lecture)
        }
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.selectedRow + 1), byExtendingSelection: false)
    }
    
    @IBAction func newBookmark(_ sender: Any) {
        if let page = pdfView.currentPage {
            let name = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
            let bookmark = Bookmark(name: name, page: page)
            bookmarkOutline.add(bookmark)
            bookmarkOutlineView.reloadData()
            bookmarkOutlineView.selectRowIndexes(IndexSet(integer: bookmarkOutlineView.numberOfRows - 1), byExtendingSelection: false)
            let cellView = bookmarkOutlineView.rowView(atRow: bookmarkOutlineView.selectedRow, makeIfNecessary: true)?.subviews.first
            let label = cellView?.subviews.first(where: {$0.identifier == NSUserInterfaceItemIdentifier(rawValue: "bookmarkName")}) as? NSTextField
            bookmarkCount += 1
            label?.stringValue = "New Bookmark \(bookmarkCount)"
            window?.makeFirstResponder(label)
        }
    }
}

class LectureSetOutline: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    private var documents = [PDFDocument]()
    private var window: DocumentWindowController? = nil
    
   func set(window: DocumentWindowController) {
        self.window = window
    }
    
    func append(_ document: PDFDocument) {
        documents.append(document)
    }
    
    func get(byURL: URL) -> PDFDocument? {
        return documents.first(where: {$0.documentURL == byURL})
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let pdf = item as? PDFDocument {
            return (pdf.page(at: index))!
        }
        return documents[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let pdf = item as? PDFDocument {
            return pdf.pageCount > 0
        }
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let pdf = item as? PDFDocument {
            return pdf.pageCount
        }
        return documents.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
            if let document = item as? PDFDocument {
                textField.stringValue = (document.documentURL?.lastPathComponent)!
            } else if let page = item as? PDFPage {
                textField.stringValue = page.label!
            }
        }
        return view
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let outlineView = notification.object as? NSOutlineView {
            let item = outlineView.item(atRow: outlineView.selectedRow)
            window?.lectureSelectionDidChange(item!)
        }
    }
}
