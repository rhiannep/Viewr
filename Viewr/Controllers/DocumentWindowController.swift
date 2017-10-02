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
// (The fat controller)
class DocumentWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    @IBOutlet weak var bookmarkOutline: BookmarkOutline!
    @IBOutlet weak var bookmarkOutlineView: NSOutlineView!
    
    @IBOutlet weak var lectureOutline: LectureSetModel!
    @IBOutlet weak var lectureOutlineView: NSOutlineView!
    
    @IBOutlet weak var pdfView: PDFView!
    
    @IBOutlet weak var toolBarTitle: NSTextField!
    @IBOutlet weak var toolBar: NSView!

    @IBOutlet var noteBox: NSTextView!
    
    @IBOutlet weak var searchBar: NSSearchField!
    @IBOutlet weak var searchResultsPop: NSPopover!
    let notes = NoteModel()
    
    var openDocumentNames = [URL]()
    var bookmarkCount = 0
    
    var presentationWindows = Set<PresentationWindowController>()
    
    // The current document in the view
    var selectedDocument : PDFDocument? = nil {
        didSet {
            pdfView.document = selectedDocument
            if selectedDocument == nil {
                window?.title = "Viewr"
                toolBar.isHidden = true
            } else {
                let name = selectedDocument?.documentURL?.lastPathComponent
                window?.title = "\(name!) (\(lectureOutline.count) open)"
                toolBarTitle.stringValue = name!
                searchBar.placeholderString = "Search in \(name!)"
                toolBar.isHidden = false
                
            }
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        lectureOutline?.set(window: self)
        bookmarkOutline?.set(owner: self)
        self.lectureOutlineView.reloadData()
        
        // Observer to change the lecture outline view when the pdf is scrolled.
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentWindowController.pdfViewScolled), name: .PDFViewPageChanged, object: pdfView)
    }
    
    func windowWillClose(_ notification: Notification) {
        (NSApplication.shared.delegate as! AppDelegate).openWindows.remove(self)
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
                            self.selectedDocument = document
                        } else {
                            self.selectedDocument = self.lectureOutline.get(byURL: url)
                            document = self.selectedDocument!
                        }
                        self.lectureOutlineView.reloadData()
                        self.selectedDocument = document
                        self.lectureOutlineView.selectRowIndexes(IndexSet(integer: self.lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
                        self.window?.makeFirstResponder(self.lectureOutlineView)
                    }
                }
            }
        })
    }
    
    // change the selcted document in the outline view when the page changes in the pdfview
    @objc func pdfViewScolled(_ notification: NSNotification) {
        let page = (notification.object as? PDFView)?.currentPage
        lectureOutlineView.expandItem(selectedDocument)
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: page)), byExtendingSelection: false)
        for window in presentationWindows {
            window.update(page)
        }
    }
    
    
    func textDidChange(_ notification: Notification) {
        if let textBox = notification.object as? NSTextView {
             if(textBox == noteBox) {
                if let document = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow) as? PDFDocument {
                    notes.add(document: document, text: textBox.attributedString())
                } else if let page = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow) as? PDFPage {
                    notes.add(page: page, text: textBox.attributedString())
                }
            }
        }
    }
    
    // called when the lecture selction changes in the lecture outline view.
    // scrolls to the appropriate page on the pdfview
    func updatePDF(_ item: Any) {
        if let document = item as? PDFDocument {
            selectedDocument = document
            pdfView.go(to: document.page(at: 0)!)
            toolBarTitle.stringValue = (document.documentURL?.lastPathComponent)!
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
            noteBox.textStorage?.setAttributedString(notes.get(document: document))
        } else if let page = item as? PDFPage {
            selectedDocument = page.document
            lectureOutlineView.expandItem(selectedDocument)
            pdfView.go(to: page)
            toolBarTitle.stringValue = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
            noteBox.textStorage?.setAttributedString(notes.get(page: page))
        } else if let bookmark = item as? Bookmark {
            updatePDF(bookmark.page)
        } else if let selection = item as? PDFSelection {
            updatePDF(selection.pages.first!)
            pdfView.go(to: selection)
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
    
    
    @IBAction func closeLecture(_ sender: Any) {
        if let lecture = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow) as? PDFDocument {
            openDocumentNames = openDocumentNames.filter({ !($0 == lecture.documentURL) })
            selectedDocument = nil
            lectureOutline.delete(lecture)
            lectureOutlineView.reloadData()
            bookmarkOutline.deleteFor(document: lecture)
            bookmarkOutlineView.reloadData()
        }
    }
    @IBAction func present(_ sender: Any) {
        let presentationWindow = PresentationWindowController(owner: self)
        presentationWindow.showWindow(self)
        presentationWindow.update(pdfView.currentPage!)
        presentationWindows.insert(presentationWindow)
    }
    
    @IBAction func removeBookmark(_ sender: Any) {
        if let bookmark = bookmarkOutlineView.item(atRow: bookmarkOutlineView.selectedRow) as? Bookmark {
            bookmarkOutline.delete(bookmark)
            bookmarkOutlineView.removeItems(at: IndexSet(integer: bookmarkOutlineView.selectedRow), inParent: nil, withAnimation: NSTableView.AnimationOptions.slideDown)
        }
        
    }
    @IBAction func searchBarActivated(_ sender: Any) {
        if let searchBar = sender as? NSSearchField {
            if (searchBar.stringValue == "") {
                pdfView.currentSelection = nil
                pdfView.highlightedSelections = nil
                searchResultsPop.close()
                return
            }
                if let results = pdfView.document?.findString(searchBar.stringValue, with: NSString.CompareOptions.caseInsensitive) {
                    pdfView.highlightedSelections = results
                    updatePDF(results.first as Any)
                    pdfView.setCurrentSelection(results.first, animate: false)
                    searchResultsPop.show(relativeTo: searchBar.visibleRect, of: searchBar, preferredEdge: .minX)
                    if let popController = searchResultsPop.contentViewController as? SearchPopoverController {
                        popController.prevNext.isEnabled = true
                        if(results.isEmpty) {
                            popController.searchResultsCountLabel.stringValue = "Nothing like \"\(searchBar.stringValue)\" found in \(selectedDocument?.documentURL?.lastPathComponent ?? "the current document")"
                            popController.prevNext.isEnabled = false
                            return
                        }
                        popController.searchResultsCountLabel.stringValue = "1 of \(results.count) found"
                    }
                }
        }
    }
    
    // Function for changing the selected search match on the pdfview.
    // Called by the previous/next controls in the search popover
    func changeSearchSelection(by: Int) {
        if(searchResultsPop.isShown) {
            if let results = pdfView.highlightedSelections {
                let currentSelectionIndex = results.index(of: pdfView.currentSelection!)
                let remainder = (currentSelectionIndex! + by) % results.count
                let nextIndex = remainder >= 0 ? remainder : remainder + results.count
                
                // Change the label on the popover view to reflect new selection
                if let popController = searchResultsPop.contentViewController as? SearchPopoverController {
                    popController.searchResultsCountLabel.stringValue = "\(nextIndex + 1) of \(results.count) found"
                }
                
                // Go to the new selection and set it as the current selection
                updatePDF(results[nextIndex])
                pdfView.setCurrentSelection(results[nextIndex], animate: true)
            }
        }
    }
    
    @IBAction func zoomToFit(_ sender: Any) {
        pdfView.autoScales = true
    }
    // Function to add a new bookmark for the current page in the pdf view to the bookmark model.
    // Handles changes to the bookmark outline view.
    @IBAction func newBookmark(_ sender: Any) {
        if let page = pdfView.currentPage {
            let name = "page \(page.label!), \((page.document?.documentURL?.lastPathComponent)!)"
            bookmarkCount += 1
            let bookmark = Bookmark(id: bookmarkCount, name: name, page: page)
            bookmarkOutline.add(bookmark)
            bookmarkOutlineView.insertItems(at: IndexSet(integer: bookmarkOutlineView.numberOfRows), inParent: nil, withAnimation: NSTableView.AnimationOptions.slideDown)
            bookmarkOutlineView.selectRowIndexes(IndexSet(integer: bookmarkOutlineView.numberOfRows - 1), byExtendingSelection: false)
            let cellView = bookmarkOutlineView.rowView(atRow: bookmarkOutlineView.selectedRow, makeIfNecessary: true)?.subviews.first
            let label = cellView?.subviews.first(where: {$0.identifier == NSUserInterfaceItemIdentifier(rawValue: "bookmarkName")}) as? NSTextField
            label?.stringValue = "New Bookmark \(bookmarkCount)"
            window?.makeFirstResponder(label)
            bookmarkOutlineView.scrollRowToVisible(bookmarkOutlineView.selectedRow)
        }
    }
}
