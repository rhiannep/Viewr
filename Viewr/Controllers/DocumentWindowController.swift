//
//  DocumentWindowController.swift
//  Viewr
//
//  Created by Rhianne Price on 15/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa
import Quartz

//
// Controller for the main window of the viewer. This controller coordinates the side bar, the pdf view, and the lecture tool bar.
// The basic thing going on here is the lecture model listening for changes in the selected document/page, and this controller updating the pdf view, as well as this controller listening for changes in the PDF View's page and updating the lecture models view. The mechanism I have used to update the view is through updating the selection in the lecture list, because I have set the controller up so that this takes care of the PDF view and the tool bar in one hit, via the listener for changes in lecture list selection.
// This controller also coordinates the model and view for the lecture notes in the tool bar.
// This controller also manages associated presentation windows.
// Using separate view contollers would result in extremely close coupling, so everything is here instead.
//
class DocumentWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    
    // Model and view for the bookmark list, along with add and remove buttons
    @IBOutlet weak var bookmarkCloseButton: NSButton!
    @IBOutlet weak var bookmarkOutline: BookmarkOutline!
    @IBOutlet weak var bookmarkOutlineView: NSOutlineView!
    @IBOutlet weak var bookmarkView: NSView!
    
    // Model and view for the lecture list, along with open and close buttons
    @IBOutlet weak var lectureOutline: LectureSetModel!
    @IBOutlet weak var lectureOutlineView: NSOutlineView!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var closeButton: NSButton!
    
    // Searchbar view elements, including the popver view displaying search results
    @IBOutlet weak var searchBarHeader: NSView!
    @IBOutlet weak var searchBar: NSSearchField!
    @IBOutlet weak var searchResultsPop: NSPopover!
    
    @IBOutlet weak var pdfView: PDFView!
    
    // Toolbar elements
    @IBOutlet weak var toolBar: NSView!
    @IBOutlet weak var toolBarTitle: NSTextField!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var previousButton: NSButton!
    
    // Model and view for saving and retrieving notes
    @IBOutlet var noteBox: NSTextView!
    let notes = NoteModel()
    
    // Syntactic sugar for getting the current selection in the lecture list view
    var currentSelection: Any? {
        get {
            return lectureOutlineView.item(atRow: lectureOutlineView.selectedRow)
        }
    }
    
    // Need to keep track of the URLs of the open documents, so we don't open the same file twice
    var openDocumentNames = [URL]()
    
    // For temporarily naming bookmarks, doesn't bother backfilling when bookmarks are removed
    var bookmarkCount = 0
    
    // Each instance of a document window own their own presentation windows
    var presentationWindows = Set<PresentationWindowController>()
    
    // The current document in the view, changing the selected document update other relevant view elements
    var selectedDocument : PDFDocument? = nil {
        didSet {
            pdfView.document = selectedDocument
            if selectedDocument == nil {
                // No lecture selected state
                window?.title = "Viewr"
                toolBar.isHidden = true
                searchBarHeader.isHidden = true
                if lectureOutline.count == 0 {
                    bookmarkView.isHidden = true
                }
                closeButton.isEnabled = false
            } else {
                // Update the window title, show the tooldbar, bookmarks list etc.
                let name = selectedDocument?.documentURL?.lastPathComponent
                window?.title = "\(name!) (\(lectureOutline.count) open)"
                toolBarTitle.stringValue = name!
                searchBar.placeholderString = "Search in \(name!)"
                toolBar.isHidden = false
                searchBarHeader.isHidden = false
                searchBar.centersPlaceholder = false
                searchBar.centersPlaceholder = true
                bookmarkView.isHidden = false
            }
        }
    }
    
    // convenience initialiser loads the correct view from it's nib file
    convenience init() {
        self.init(windowNibName: "DocumentWindow")
    }
    
    // Once the window has loaded, initialise view elements and register notifications
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Resize the window to full screen
        if let screen = NSScreen.main() {
            window?.setFrame(screen.visibleFrame, display: true, animate: true)
        }
        
        // pass a reference to this controller to the model elements
        lectureOutline?.set(window: self)
        bookmarkOutline?.set(owner: self)
        
        // Observer to change the lecture outline view when the pdf is scrolled.
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentWindowController.pdfViewChangedPage), name: .PDFViewPageChanged, object: pdfView)
    }
    
    // Close all associated presentation windows, and keep the app delegate up to date on close.
    func windowWillClose(_ notification: Notification) {
        for window in presentationWindows {
            window.close()
        }
        (NSApplication.shared().delegate as! AppDelegate).openWindows.remove(self)
    }
    

    
    // Function to handle the opening of documents
    // triggered by the "+" button at the top of the lecture list
    // The most recently opened document is selected in the outline view.
    // Can open mutiple documents at once.
    @IBAction func openPDF(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = ["pdf"]
        
        // Open a model window for opening a document
        openPanel.beginSheetModal(for: self.window!, completionHandler: {(status) in
            if status == NSFileHandlingPanelOKButton {
                for url in openPanel.urls {
                    if var document = PDFDocument(url: url) {
                        if !self.openDocumentNames.contains(url) {
                            // Only open the document if it isnt already open
                            self.lectureOutline.append(document)
                            self.openDocumentNames.append(url)
                            self.selectedDocument = document
                        } else {
                            // If it is already open, select that document
                            self.selectedDocument = self.lectureOutline.get(byURL: url)
                            document = self.selectedDocument!
                        }
                        // Select the new document in the lecture list view
                        self.lectureOutlineView.reloadData()
                        self.selectedDocument = document
                        self.lectureOutlineView.selectRowIndexes(IndexSet(integer: self.lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
                        self.nextButton?.isEnabled = true
                        self.window?.makeFirstResponder(self.lectureOutlineView)
                    }
                }
            }
        })
    }
    
    // change the selcted document in the outline view when the page changes in the pdfview
    @objc func pdfViewChangedPage(_ notification: NSNotification) {
        let page = (notification.object as? PDFView)?.currentPage
        // Expand the document in the lecture list
        lectureOutlineView.expandItem(selectedDocument)
        // Select the new page in the lecture list
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: page)), byExtendingSelection: false)
        
        // Also, notify the presntation windows that the page has changed
        for window in presentationWindows {
            window.update(page)
        }
    }
    
    // Fired when text is added in the notes box, saves the new text in the notes model
    func textDidChange(_ notification: Notification) {
        if let textBox = notification.object as? NSTextView {
             if(textBox == noteBox) {
                // Only worry about the notes box
                if let document = currentSelection as? PDFDocument {
                    // add the note to the current documents notes
                    notes.add(document: document, text: textBox.attributedString())
                } else if let page = currentSelection as? PDFPage {
                    // add the note to the current pages notes
                    notes.add(page: page, text: textBox.attributedString())
                }
            }
        }
    }
    
    // Function for updating the PDF View.
    // Called when the lecture selction changes in the lecture list.
    // Scrolls to the appropriate page on the pdfview
    func updatePDF(_ item: Any) {
        if let document = item as? PDFDocument {
            // If the selected item is a document, got to the first page of the document, but the document itself in the toolbar.
            selectedDocument = document
            pdfView.go(to: document.page(at: 0)!)
            toolBarTitle.stringValue = (document.documentURL?.lastPathComponent)!
            // load the document's notes from the notes model
            noteBox.textStorage?.setAttributedString(notes.get(document: document))
            // Hack to fix bug: Since the PDF Page may have changed and the PDF View is on page 1 of this document, the function responding to changes in the PDF page selects the lecture list at page 1, so, select the document again, but this time the page won't change.
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: document)), byExtendingSelection: false)
        } else if let page = item as? PDFPage {
            // if the selected item is a page
            selectedDocument = page.document
            
            // go to the new page
            lectureOutlineView.expandItem(selectedDocument)
            pdfView.go(to: page)
            toolBarTitle.stringValue = "\((page.document?.documentURL?.lastPathComponent)!) page \(page.label!)"
            // load the page notes from the model
            noteBox.textStorage?.setAttributedString(notes.get(page: page))
        } else if let bookmark = item as? Bookmark {
            // go to the bookmarked page
            updatePDF(bookmark.page)
        } else if let selection = item as? PDFSelection {
            // Used by the search tabber, go to the page where the slection first appears, then go to the selectionon that page.
            updatePDF(selection.pages.first!)
            pdfView.go(to: selection)
        }
        // scroll the selected row to visible
        lectureOutlineView.scrollRowToVisible(lectureOutlineView.selectedRow)
    }
    
    // Function for seleting the next document in the lecture list, skipping over any pages in between.
    // Triggered by the menu item for "Next Lecture" or the corresponding keyboard shortcut
    @IBAction func nextLecture(_ sender: Any) {
        if selectedDocument == nil {
            return
        }
        
        // Consult the model to see if there is a next lecture
        if let nextLecture = lectureOutline.getRelativeTo(selectedDocument!, by: 1) {
            // Only select the next lecture if there is one
             lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: nextLecture)), byExtendingSelection: false)
        }
    }
    
    // Function for selecting the previous document in the lecture list, skipping over any pages in between.
    // Triggered by the menu item for "Previous Lecture" or the corresponding keyboard shortcut
    @IBAction func previousLecture(_ sender: Any) {
        if selectedDocument == nil {
            return
        }
        // Consult the model to see if there is a previous lecture
        if let previousLecture = lectureOutline.getRelativeTo(selectedDocument!, by: -1) {
            // Only select the previous lecture if there is one
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.row(forItem: previousLecture)), byExtendingSelection: false)
        }
    }
    
    // Changes the selection on the lecture outline view to the next item when the "next" control is hit.
    // The PDF View then changes when the lecture outline delegate is notified.
    // The selected item in the lecture list can be a document, or a page within a document
    @IBAction func goToNextOutlineItem(_ sender: Any) {
        if let lecture = currentSelection as? PDFDocument {
            // If a document is currently selected, the next item will be the first page of that document, so we have to expand the document to select the first page.
            lectureOutlineView.expandItem(lecture)
        }
        
        // Select the next item. Fails Quietly if there is nothing there, but control validation should take care of this anyway.
        lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.selectedRow + 1), byExtendingSelection: false)
    }
    
    // Changes the selection on the lecture outline view to the previous item when the "previous" control is hit.
    // The PDF View then changes when the lecture outline delegate is notified.
    // The selected item in the lecture list can be a document, or a page within a document
    @IBAction func goToPreviousOutlineItem(_ sender: Any) {
        if let previous = lectureOutlineView.item(atRow: lectureOutlineView.selectedRow - 1) {
            if let lecture = previous as? PDFDocument {
                lectureOutlineView.expandItem(lecture)
            }
            lectureOutlineView.selectRowIndexes(IndexSet(integer: lectureOutlineView.selectedRow - 1), byExtendingSelection: false)
        }
    }
    

    
    // Closes the currently selected lecture, and deletes any bookmarks that point to that lecture.
    @IBAction func closeLecture(_ sender: Any) {
        if let lecture = currentSelection as? PDFDocument {
            // Only allow closure if current selection in the lecture list is a document.
            
            // Remove the selected lecture from the open document URLs, so that it can be reopened in future
            openDocumentNames = openDocumentNames.filter({ !($0 == lecture.documentURL) })
            
            // Remove the selected lecture from the leture model
            lectureOutline.delete(lecture)
            selectedDocument = nil
            
            // Reloading the lecture list view selects the fist item, so if there is a document open, the first open document will become the new selection.
            lectureOutlineView.reloadData()
            
            // Delete all the corresponding bookmarks from the model and reload the view
            bookmarkOutline.deleteFor(document: lecture)
            bookmarkOutlineView.reloadData()
        }
    }
    
    // Function to add a new bookmark at the current page in the pdf view to the bookmark model.
    // Handles changes to the bookmark list view.
    @IBAction func newBookmark(_ sender: Any) {
        if let page = pdfView.currentPage {
            // Bookmark name is the bookmarked pages page number and document name
            let name = "page \(page.label!), \((page.document?.documentURL?.lastPathComponent)!)"
            bookmarkCount += 1
            
            // Create a new bookmark for th current page an add it to the model
            let bookmark = Bookmark(id: bookmarkCount, name: name, page: page)
            bookmarkOutline.add(bookmark)
            
            // Update the view to show the new bookmark, and select it
            bookmarkOutlineView.insertItems(at: IndexSet(integer: bookmarkOutlineView.numberOfRows), inParent: nil, withAnimation: NSTableViewAnimationOptions.slideDown)
            bookmarkOutlineView.selectRowIndexes(IndexSet(integer: bookmarkOutlineView.numberOfRows - 1), byExtendingSelection: false)
            
            // Add a user editable label to the view element representing the new bookmark (fails quietly if the view can't be found)
            let cellView = bookmarkOutlineView.rowView(atRow: bookmarkOutlineView.selectedRow, makeIfNecessary: true)?.subviews.first
            let label = cellView?.subviews.first(where: {$0.identifier == "bookmarkName"}) as? NSTextField
            
            // Make the temporary label include the number of bookmarks ever created
            label?.stringValue = "New Bookmark \(bookmarkCount)"
            
            // Put focus on the editable bookmark label so that the user is prompted to make a new label.
            window?.makeFirstResponder(label)
            bookmarkOutlineView.scrollRowToVisible(bookmarkOutlineView.selectedRow)
        }
    }
    
    // Removes the currently selected bookmark from the model and updates the relevant view elements
    @IBAction func removeBookmark(_ sender: Any) {
        let selectedRow = bookmarkOutlineView.selectedRow
        if let bookmark = bookmarkOutlineView.item(atRow: bookmarkOutlineView.selectedRow) as? Bookmark {
            // Remove selected bookmark from model if one is selected
            bookmarkOutline.delete(bookmark)
            
            // Remove the selected bookmark from the list view, then select the one above the removed bookmark, or the one below if there is nothing above
            bookmarkOutlineView.removeItems(at: IndexSet(integer: bookmarkOutlineView.selectedRow), inParent: nil, withAnimation: NSTableViewAnimationOptions.slideDown)
            bookmarkOutlineView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
            if bookmarkOutlineView.selectedRow == -1 {
                bookmarkOutlineView.selectRowIndexes(IndexSet(integer: selectedRow - 1), byExtendingSelection: false)
            }
        }
        
    }
    
    // Scale the PDF to fit the window
    @IBAction func zoomPDFToFit(_ sender: Any) {
        pdfView.autoScales = true
    }
    
    // Open a new presentation window initialised with the current PDF Page
    @IBAction func present(_ sender: Any) {
        if let currentPage = pdfView.currentPage {
            let presentationWindow = PresentationWindowController(owner: self)
            presentationWindow.showWindow(self)
            presentationWindow.update(currentPage)
            presentationWindows.insert(presentationWindow)
        }
    }
    
    // Fired when the text in the search bar is changed
    // Searches the current document for the search term, opens the opopover for tabbing through search results, and selects thefirst search result
    @IBAction func searchBarActivated(_ sender: Any) {
        if let searchBar = sender as? NSSearchField {
            if (searchBar.stringValue == "") {
                // Give up if the search term is empty
                pdfView.currentSelection = nil
                pdfView.highlightedSelections = nil
                searchResultsPop.close()
                return
            }
                if let results = pdfView.document?.findString(searchBar.stringValue, withOptions: Int(NSString.CompareOptions.caseInsensitive.rawValue)) {
                    
                    // highlight search results
                    pdfView.highlightedSelections = results
                    
                    // go to the first selection in results
                    updatePDF(results.first as Any)
                    
                    // yellow box to show the first result is being selected
                    pdfView.setCurrentSelection(results.first, animate: false)
                    
                    // Show the searh results popover with the appropriate message for the results found
                    searchResultsPop.show(relativeTo: searchBar.visibleRect, of: searchBar, preferredEdge: .minX)
                    if let popController = searchResultsPop.contentViewController as? SearchPopoverController {
                        popController.prevNext.isEnabled = true
                        if(results.isEmpty) {
                            var shortenedSearchTerm = searchBar.stringValue
                            if searchBar.stringValue.characters.count > 17 {
                                let index = searchBar.stringValue.index(searchBar.stringValue.startIndex, offsetBy: 14)
                                shortenedSearchTerm = searchBar.stringValue.substring(to: index) + "..."
                            }
                            popController.searchResultsCountLabel.stringValue = "Nothing like \"\(shortenedSearchTerm)\" found in \(selectedDocument?.documentURL?.lastPathComponent ?? "the current document")"
                            popController.prevNext.isEnabled = false
                            return
                        }
                        popController.searchResultsCountLabel.stringValue = "1 of \(results.count) found"
                    }
                }
        }
    }
    
    // Function for changing the selected search match.
    // Called by the previous/next controls in the search popover.
    // Changes the selected search result when the results are tabbed through
    func changeSearchSelection(by: Int) {
        if(searchResultsPop.isShown) {
            // If the popver isn't shown don't bother
            if let results = pdfView.highlightedSelections {
                // If the PDF has current selections
                let currentSelectionIndex = results.index(of: pdfView.currentSelection!)
                
                // modulo the index of the next selection so that the list is circular, ie hitting next from the last goes to the first and vice versa
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
    
    @IBAction func find(_ sender: Any) {
        window?.makeFirstResponder(searchBar)
    }
    
    // Validate the appropriate menu items when the responder chain gets to this controller.
    // Navigation, open, and present menu items need information from this controller to be validated.
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(DocumentWindowController.nextLecture)?:
            if selectedDocument == nil {
                return false
            }
            if lectureOutline.getRelativeTo(selectedDocument!, by: 1) != nil {
                return true
            }
        case #selector(DocumentWindowController.previousLecture)?:
            if selectedDocument == nil {
                return false
            }
            if lectureOutline.getRelativeTo(selectedDocument!, by: -1) != nil {
                return true
            }
        case #selector(DocumentWindowController.openPDF)?:
            return true
        case #selector(DocumentWindowController.present)?:
            return selectedDocument != nil
        case #selector(DocumentWindowController.goToNextOutlineItem)?:
            if selectedDocument == nil {
                return false
            }
            return nextButton.isEnabled
        case #selector(DocumentWindowController.goToPreviousOutlineItem)?:
            if selectedDocument == nil {
                return false
            }
            return previousButton.isEnabled
        case #selector(DocumentWindowController.find)?:
            if selectedDocument != nil {
                return true
            }
        default:
            return false
        }
        return false
    }
}
