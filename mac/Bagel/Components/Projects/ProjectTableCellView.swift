//
//  ProjectTableCellView.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 30/08/2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

class ProjectTableCellView: NSTableCellView {

    @IBOutlet weak var backgroundBox: NSBox!
    @IBOutlet weak var titleTextField: NSTextField!
    
    var project: BagelProjectController!
    var isSelected = false

    func refresh() {
        
        self.titleTextField.stringValue = self.project.projectName ?? ""
        self.backgroundBox.isHidden = !self.isSelected
        
        if self.isSelected {
            
            self.titleTextField.font = FontManager.mainMediumFont(size: 14)
            self.titleTextField.textColor = BagelColors.projectText
        }else {
            
            self.titleTextField.font = FontManager.mainFont(size: 14)
            self.titleTextField.textColor = BagelColors.secondaryLabel
        }
    }
}
