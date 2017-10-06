//
//  LectureModel.swift
//  Viewr
//
//  Created by Rhianne Price on 2/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Foundation
import Quartz

//
// A model class for the lectures currently open, used as a data source and delegate for the lecture outline in the document window
//
class LectureSetModel: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    // All the documents currently open, to be shown in the lecture list view
    private var documents = [PDFDocument]()
    
    // The window controller that owns this file. A reference is held here so that the model can alert the controller to changes to the lecture list.
    private var window: DocumentWindowController? = nil
    
    // returns the number of documents in the model
    var count: Int {
        get {
            return documents.count
        }
    }
    
    // Setter for the owning window
    func set(window: DocumentWindowController) {
        self.window = window
    }
    
    // Add a given document to the model
    func append(_ document: PDFDocument) {
        documents.append(document)
    }
    
    // Delete a given document from the model
    func delete(_ document: PDFDocument) {
        documents = documents.filter({ !($0 == document) })
    }
    
    // Get a Document by it's URL
    func get(byURL: URL) -> PDFDocument? {
        return documents.first(where: {$0.documentURL == byURL})
    }
    
    // Given a document, try fin it in the model and then return another document that is n awy from the given document
    // Used to find the next and previous lectures.
    // Optional because their might not be a next or previous lecture
    func getRelativeTo(_ currentDocument: PDFDocument, by: Int) -> PDFDocument? {
        if let indexOfCurrentDocument = documents.index(of: currentDocument) {
            // If the given document is in the model
            
            let newIndex = indexOfCurrentDocument + by
            if documents.indices.contains(newIndex) {
                // If the new index is viable
                return documents[newIndex]
            }
        }
        return nil
    }
    
    // NSOUTLINEVIEWDATASOURCE METHODS
    
    // Given an index and a document, returns the page at the index, but when given just an index, returns the document at the index.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let pdf = item as? PDFDocument {
            return (pdf.page(at: index))!
        }
        return documents[index]
    }
    
    // Determines whether an item is expandable
    // Expandable items are PDF Documents with 1 or more pages.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let pdf = item as? PDFDocument {
            return pdf.pageCount > 0
        }
        return false
    }
    
    // Given a PDF document, returns the number of pages in that document, or just the number of documents in the model
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let pdf = item as? PDFDocument {
            return pdf.pageCount
        }
        return documents.count
    }
    
    // Initialises and returns a new view for the given item, and gives the textField in that view the appropriate value
    // Not really a model function
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: "cell", owner: self) as? NSTableCellView
        if let textField = view?.textField {
            if let document = item as? PDFDocument {
                // Documents should display their name
                textField.stringValue = (document.documentURL?.lastPathComponent)!
            } else if let page = item as? PDFPage {
                //pages should display their page number
                textField.stringValue = page.label!
            }
        }
        return view
    }
    
    // Listens for changes in the lecture list view and notifies the window controller that the PDF should change
    // Also handles validation of the navigation, and open/close lecture controls
    // This is really controller logic but I wanted the NSOutlineViewDelegate and NSOutlineViewDataSource to be the same class
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let outlineView = notification.object as? NSOutlineView {
            if let item = outlineView.item(atRow: outlineView.selectedRow) {
                // Disable the next button if we are on the last page of the last lecture
                if outlineView.selectedRow == outlineView.numberOfRows - 1 {
                    if item is PDFPage {
                        window?.nextButton.isEnabled = false
                    }
                } else {
                    window?.nextButton.isEnabled = true
                }
                
                // disable previous if we are at the first item
                if outlineView.selectedRow == 0 {
                    window?.previousButton.isEnabled = false
                } else {
                    window?.previousButton.isEnabled = true
                }
                
                // Disable the close button if no document is selected
                if item is PDFDocument {
                    window?.closeButton.isEnabled = true
                } else {
                    window?.closeButton.isEnabled = false
                }
                // Update the PDF in the window controllwe
                window?.updatePDF(item)
            }
        }
    }
}
