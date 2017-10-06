//
//  NoteModel.swift
//  Viewr
//
//  Created by Rhianne Price on 1/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

// Struct representing a page, used as keys for the note model
// If I had used PDFPages as keys they would have a different hash value for every time a the same PDF is opened.
// Users can close and reopen the same PDF in the same session and the notes will still appear. This was in preparaion for persistent storage hich I didn't end up implementing
struct Page: Equatable, Hashable {
    let documentURL: URL
    let pageNumber: Int
    let hashValue: Int
    
    // Initialiser pulls the given pdf page apart so that it can be uniquely identified
    init(_ page: PDFPage) {
        documentURL = (page.document?.documentURL)!
        pageNumber = Int(page.label!)!
        hashValue = documentURL.hashValue + pageNumber
    }
    
    // An entire document is represented as "page 0" of the document
    init(_ document: PDFDocument) {
        documentURL = (document.documentURL)!
        pageNumber = 0
        hashValue = documentURL.hashValue + pageNumber
    }
    
    // Pages are equal if they have the name page number in the same document
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.documentURL == rhs.documentURL && lhs.pageNumber == rhs.pageNumber
    }
}

//
// Model for storing notes
// Dictionary of attributed strings (for RTF) indexed by pages (where a document is page 0) wrapped in add/get functionality
//
class NoteModel {
    private var notes = [Page: NSAttributedString]()
    
    // Add an attributed string to the model at the given page
    func add(page: PDFPage, text: NSAttributedString) {
        notes[Page(page)] = text.copy() as? NSAttributedString
    }
    
    // Add an attributed string to the model at the given document (page 0)
    func add(document: PDFDocument, text: NSAttributedString) {
        notes[Page(document)] = text.copy() as? NSAttributedString
    }
    
    // Get the attributed string corresponding to the given page
    func get(page: PDFPage) -> NSAttributedString {
        return notes[Page(page)] ?? NSAttributedString(string: "")
    }
    
    // Get the attributed string corresponding to the given document
    func get(document: PDFDocument) -> NSAttributedString {
        return notes[Page(document)] ?? NSAttributedString(string: "")
    }
}
