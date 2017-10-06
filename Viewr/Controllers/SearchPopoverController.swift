//
//  SearchPopoverController.swift
//  Viewr
//
//  Created by Rhianne Price on 2/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa


//
// Controller for the popver view that diplays serach results
// Delegates tabbing through search results to the DocumenWindowController, because the PDF View must be accessed and updated
//
class SearchPopoverController: NSViewController {
    
    // Needs a reference to it's DocumenWindowController so that the tabbing can be delegated
    @IBOutlet weak var documentWindowController: DocumentWindowController!
    // View element that shows how many results were found, or if none were found. Accessed by the documnet window controller.
    @IBOutlet weak var searchResultsCountLabel: NSTextField!
    // Buttons for tabbing through search results, refferred to here for validation by the document window controller.
    @IBOutlet weak var prevNext: NSSegmentedControl!
    
    // Function fires when the previous/next buttons in the popover are hit
    // This function just works out which button was hit and forwards that on the the appropriate method in the document window controller
    @IBAction func gotToSelection(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            // if previous hit
            documentWindowController.changeSearchSelection(by: -1)
        } else if sender.selectedSegment == 1 {
            // if next hit
            documentWindowController.changeSearchSelection(by: 1)
        }
    }
}
