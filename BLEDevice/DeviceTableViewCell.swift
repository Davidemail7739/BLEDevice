//
//  DeviceTableViewCell.swift
//  BLEDevice
//
//  Created by David on 2022/2/28.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var labelName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func bluetoothWithDevice(name: String) {
        self.labelName.text = name
    }
}
