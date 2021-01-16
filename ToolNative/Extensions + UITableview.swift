//
//  Extensions + UITableview.swift
//  ToolNative
//
//  Created by Marcin Kessler on 17.10.20.
//

import Foundation
import UIKit

//MARK:-Empty Tableview
extension UITableView {
    
    public func setEmptyView(message: String, localizedComment : String = "") {
        
        let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        emptyLabel.text = NSLocalizedString(message, comment: localizedComment == "" ? message : localizedComment)
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.boldSystemFont(ofSize: 17)
        emptyLabel.lineBreakMode = .byWordWrapping
        emptyLabel.numberOfLines = 0
        
        //MARK:- Style
        emptyLabel.textColor = .secondaryLabel
        
        self.backgroundView = emptyLabel
//        self.separatorStyle = .none
    }
    
    public func setEmptyView(message: NSAttributedString) {
        
        let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        emptyLabel.attributedText = message
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.boldSystemFont(ofSize: 17)
        emptyLabel.lineBreakMode = .byWordWrapping
        emptyLabel.numberOfLines = 0
        
        
        self.backgroundView = emptyLabel
//        self.separatorStyle = .none
    }
    
    public func removeEmptyView(_ separatorstyle: UITableViewCell.SeparatorStyle = .none) {
        
        self.backgroundView = nil
//        self.separatorStyle = separatorstyle
        
    }
    
}


extension String {
    func isBohrer() -> Bool {
        if self.prefix(1) == "B" {
            return true
        }
        return false
    }
}
