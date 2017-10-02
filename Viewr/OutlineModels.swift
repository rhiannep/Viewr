//
//  OutlineModels.swift
//  Viewr
//
//  Created by Rhianne Price on 30/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation

import Quartz

// A model class for the lectures currently open, used as a data source and delegate for the lecture outline in the document window
class LectureSetModel: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    private var documents = [PDFDocument]()
    private var window: DocumentWindowController? = nil
    
    var count: Int {
        get {
            return documents.count
        }
    }
    
    func set(window: DocumentWindowController) {
        self.window = window
    }
    
    func append(_ document: PDFDocument) {
        documents.append(document)
    }
    
    func delete(_ document: PDFDocument) {
         documents = documents.filter({ !($0 == document) })
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
            if let item = outlineView.item(atRow: outlineView.selectedRow) {
                window?.lectureSelectionDidChange(item)
            }
        }
    }
}

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
}
