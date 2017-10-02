//
//  SearchPopoverController.swift
//  Viewr
//
//  Created by Rhianne Price on 2/10/17.
//  Copyright © 2017 Rhianne Price. All rights reserved.
//

import Cocoa

class SearchPopoverController: NSViewController {

    @IBOutlet weak var documentWindowController: DocumentWindowController!
    
    @IBOutlet weak var searchResultsCountLabel: NSTextField!
    
    @IBOutlet weak var prevNext: NSSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func gotToSelection(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            documentWindowController.changeSearchSelection(by: -1)
        } else if sender.selectedSegment == 1 {
            documentWindowController.changeSearchSelection(by: 1)
        }
    }
}
