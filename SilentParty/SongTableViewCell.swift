//
//  SongTableViewCell.swift
//  SilentParty
//
//  Created by GuoGongbin on 2/4/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
