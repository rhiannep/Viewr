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
    

    @IBOutlet weak var pdfView: PDFView!

    @IBOutlet weak var toolBarTitle: NSTextField!
    
    @IBOutlet weak var toolBar: NSView!
    
    @IBOutlet weak var outline: LectureSetOutline!
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var openDocuments = 0
    var openDocumentNames = [URL]()
    
    
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
                            self.outline.append(document)
                            self.openDocumentNames.append(url)
                            self.openDocuments += 1
                            self.selectedDocument = document
                        } else {
                            self.selectedDocument = self.outline.get(byURL: url)
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
        outline?.set(window: self)
        self.outlineView.reloadData()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func lectureSelectionDidChange(_ item: Any) {
        if let document = item as? PDFDocument {
            selectedDocument = document
            toolBarTitle.stringValue = (document.documentURL?.lastPathComponent)!
        } else if let page = item as? PDFPage {
            selectedDocument = page.document
            pdfView.go(to: page)
            toolBarTitle.stringValue = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
        }
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
        if outlineView.selectedRow == outlineView.numberOfRows - 1 {
            return
        }
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.selectedRow + 1), byExtendingSelection: false)
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
                if #available(OSX 10.13, *) {
                    view?.imageView?.image = page.thumbnail(of: (view?.imageView?.image?.size)!, for: PDFDisplayBox.mediaBox)
                } else {
                    view?.imageView = NSImageView(image: NSImage(data: page.dataRepresentation)!)
                }
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
