//
//  LectureModel.swift
//  Viewr
//
//  Created by Rhianne Price on 2/10/17.
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
                window?.updatePDF(item)
            }
        }
    }
}
