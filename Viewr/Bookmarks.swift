//
//  Bookmarks.swift
//  Viewr
//
//  Created by Rhianne Price on 29/09/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

class Bookmarks {
    private var bookmarks = [String: PDFPage]()
    
    func add(name: String, page: PDFPage) {
        bookmarks[name] = page
    }
    
    func get(byName: String) -> PDFPage? {
        return bookmarks[byName]
    }
}

class BookmarkOutline: NSObject, NSOutlineViewDataSource {
    
    private var bookmarks = [String]()
    
    func append(_ name: String) {
        bookmarks.append(name)
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return bookmarks[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
}
