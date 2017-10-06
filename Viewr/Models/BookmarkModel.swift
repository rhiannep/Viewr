//
//  BookmarkModel.swift
//  Viewr
//
//  Created by Rhianne Price on 30/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

// Struct for representing a bookmark
struct Bookmark {
    let id: Int
    let name: String
    let page: PDFPage
}

//
// Model for storing bookmarks, acts as the data source and delegate for the bookmark list
// Pretty much an array of Bookmarks with the methods NSOutlineView needs to present the data
//
class BookmarkOutline: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    // All the bookmarks to be shown in the bookmark list view
    private var bookmarks = [Bookmark]()
    
     // The window controller that owns this file. A reference is held here so that the model can alert the controller to changes to the bookmark list.
    private var owner: DocumentWindowController? = nil
    
    // Add a bookmark to the model
    func add(_ bookmark: Bookmark) {
        bookmarks.append(bookmark)
    }
    
    // Remove a bookmark from the model
    func delete(_ bookmark: Bookmark) {
        bookmarks = bookmarks.filter({ !($0.id == bookmark.id) })
    }
    
    // Delete all the bookmarks that are for the given document
    func deleteFor(document: PDFDocument) {
        bookmarks = bookmarks.filter({ !($0.page.document == document) })
    }
    
    // Setter for the owning window
    func set(owner: DocumentWindowController) {
        self.owner = owner
    }
    
    // Function for jumping to the page given a bookmark
    // This needs to go here because each bookmark in the list view has it's own button for jumping to a ookmark
    @IBAction func goToBookmark(_ sender: NSButtonCell) {
        if let cell = sender.representedObject as? NSTableCellView {
            if let bookmark = cell.objectValue as? Bookmark {
                owner?.updatePDF(bookmark)
            }
        }
    }
    
    // When given just an index, returns the bookmark at the index.
    // The list is 1 level deep, so the item parameter is alwas nil
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return bookmarks[index]
    }
    
    // Determines whether an item is expandable
    // The list is 1 level deep, so this always returns false
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    // Returns the number of bookmarks in the model, item is always nil
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return bookmarks.count
    }
    
    // Initialises and returns a new view for the given bookmark, and gives the textFields in that view the appropriate value
    // Not really a model function
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: "cell", owner: self) as? NSTableCellView
        if let textField = view?.textField {
            if let bookmark = item as? Bookmark {
                textField.stringValue = bookmark.name
                view?.objectValue = bookmark
            }
        }
        return view
    }
    
    // Listens for changes in the bookmark list view handles validation of the delete bookmark button
    // This is really controller logic but I wanted the NSOutlineViewDelegate and NSOutlineViewDataSource to be the same class
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let outlineView = notification.object as? NSOutlineView {
            owner?.bookmarkCloseButton.isEnabled = false
            if let item = outlineView.item(atRow: outlineView.selectedRow) {
                if item is Bookmark {
                    owner?.bookmarkCloseButton.isEnabled = true
                }
            }
        }
    }
}
