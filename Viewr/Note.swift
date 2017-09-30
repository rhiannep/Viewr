//
//  Note.swift
//  Viewr
//
//  Created by Rhianne Price on 1/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

struct Page: Equatable, Hashable {
    let documentURL: URL
    let pageNumber: Int
    let hashValue: Int
    
    init(page: PDFPage) {
        documentURL = (page.document?.documentURL)!
        pageNumber = Int(page.label!)!
        hashValue = documentURL.hashValue + pageNumber
    }
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.documentURL == rhs.documentURL && lhs.pageNumber == rhs.pageNumber
    }
}

class NoteModel {
    private var notes = [Page: NSTextView]()
    
    func add(page: PDFPage, text: NSTextView) {
        notes[Page(page: page)] = text
    }
    
    func get(page: PDFPage) -> NSTextView? {
        return notes[Page(page: page)]
    }
}
