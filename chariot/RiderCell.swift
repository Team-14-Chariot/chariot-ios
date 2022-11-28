//
//  RiderCell.swift
//  chariot
//
//  Created by Reese Crowell on 11/28/22.
//

import UIKit

class RiderCell: UITableViewCell {

    @IBOutlet weak var riderImage: UIImageView!
    @IBOutlet weak var riderName: UILabel!
    @IBOutlet weak var pickupAddress: UILabel!
    @IBOutlet weak var dropoffAddress: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
