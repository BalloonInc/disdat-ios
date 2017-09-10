//
//  AchievementsFooter.swift
//  DisDat
//
//  Created by Wouter Devriendt on 10/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class AchievementsHeader: UICollectionReusableView {
    @IBOutlet weak var headerLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        headerLabel.text = String(format: NSLocalizedString("🤖 You found %d/%d words.", comment: ""), DiscoveredWordCollection.getInstance()!.getCurrentDiscoveredCount(),DiscoveredWordCollection.getInstance()!.totalWordCount)
    }
}
