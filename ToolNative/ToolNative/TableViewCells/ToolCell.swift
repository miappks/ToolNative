//
//  ToolCell.swift
//  ToolNative
//
//  Created by Marcin Kessler on 16.10.20.
//

import UIKit

class ToolCell: UITableViewCell {

    @IBOutlet weak var toolNumber: UILabel!
    @IBOutlet weak var toolType: UILabel!
    @IBOutlet weak var internalToolID: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
