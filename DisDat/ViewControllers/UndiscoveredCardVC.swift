//
//  UnknownCardVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 08/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class UndiscoveredCardVC: UIViewController {

    @IBOutlet weak var unknownCardLabel: UILabel!
    
    var unknownCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        if unknownCount > 0 {
            unknownCardLabel.text = String(format: NSLocalizedString("Still %d undiscovered words in this category. Go out and scan some!", comment: ""), unknownCount)
        }
        else {
            unknownCardLabel.text = nil
        }
    }

}
