//
//  ImageFullScreenViewController.swift
//  Winkln.be
//
//  Created by Wouter Devriendt on 26/06/2016.
//  Copyright © 2016 Balloon Inc. All rights reserved.
//

import UIKit

class ImageFullScreenViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!

    var image: UIImage?

    override func viewDidLoad() {
        self.scrollView.delegate = self
        self.scrollView.contentSize = imageView.bounds.size
        self.scrollView.maximumZoomScale = 4.0
        self.imageView.image = image
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    @IBAction func doubleTappedToZoom(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale + (scrollView.maximumZoomScale - scrollView.minimumZoomScale) * 0.25 {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }

    }

}
