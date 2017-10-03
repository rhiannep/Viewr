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

// Model for storing bookmarks, acts as the data source and delegate for the outline view that lists the book marks
class BookmarkOutline: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    private var bookmarks = [Bookmark]()
    private var bookmarkNames = [String]()
    private var owner: DocumentWindowController? = nil
    
    func add(_ bookmark: Bookmark) {
        bookmarks.append(bookmark)
    }
    
    func delete(_ bookmark: Bookmark) {
        bookmarks = bookmarks.filter({ !($0.id == bookmark.id) })
    }
    
    func deleteFor(document: PDFDocument) {
        bookmarks = bookmarks.filter({ !($0.page.document == document) })
    }
    
    func get(byName: String) -> Bookmark? {
        return bookmarks.first(where: {$0.name == byName})
    }
    
    func set(owner: DocumentWindowController) {
        self.owner = owner
    }
    
    @IBAction func goToBookmark(_ sender: NSButtonCell) {
        if let cell = sender.representedObject as? NSTableCellView {
            if let bookmark = cell.objectValue as? Bookmark {
                owner?.updatePDF(bookmark)
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return bookmarks[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return bookmarks.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
            if let bookmark = item as? Bookmark {
                textField.stringValue = bookmark.name
                view?.objectValue = bookmark
            }
        }
        return view
    }
    
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
