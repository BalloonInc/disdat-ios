//
//  Constants.swift
//  DisDat
//
//  Created by Wouter Devriendt on 01/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation

struct Constants {
    struct error {
        static let login = NSLocalizedString("An error occurred during login", comment:"")
        static let logout = NSLocalizedString("An error occurred during logout", comment:"")
        static let tryAgain = NSLocalizedString("Oops, let me try again!", comment:"")
    }
    
    struct config {
        static let image_resize_width = "image_resize_width"
        static let debug_enabled = "debug_enabled"
        static let super_debug_enabled = "super_debug_enabled"
    }
}
