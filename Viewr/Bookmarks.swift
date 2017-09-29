//
//  Bookmarks.swift
//  Viewr
//
//  Created by Rhianne Price on 29/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

struct Bookmark {
    let name: String
    let page: PDFPage
}

class BookmarkOutline: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    private var bookmarks = [Bookmark]()
    private var bookmarkNames = [String]()
    private var owner: DocumentWindowController? = nil
    
    func add(name: String, page: PDFPage) {
        bookmarks.append(Bookmark(name: name, page: page))
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
                owner?.lectureSelectionDidChange(bookmark)
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
            if let item = outlineView.item(atRow: outlineView.selectedRow) {
              owner?.lectureSelectionDidChange(item)
            }
        }
    }
}
