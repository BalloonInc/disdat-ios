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
    @IBOutlet weak var cardView: UIView?
    
    var unknownCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView?.layer.shadowColor = #colorLiteral(red: 0.1490027606, green: 0.1490303874, blue: 0.1489966214, alpha: 1)
        
        cardView?.layer.shadowOpacity = 0.3;
        cardView?.layer.shadowRadius = 1.0;
        cardView?.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        
        if unknownCount > 0 {
            unknownCardLabel.text = String(format: NSLocalizedString("Still %d undiscovered words in this category. Go out and scan some!", comment: ""), unknownCount)
        }
        else {
            unknownCardLabel.text = nil
        }
    }

}
