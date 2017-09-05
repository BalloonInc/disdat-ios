//
//  SpeechBubble.swift
//  DisDat
//
//  Created by Wouter Devriendt on 05/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation
import UIKit

class SpeechBubble: UIView {
    let fillColor = UIColor.white
    var triangleHeight: CGFloat!
    var radius: CGFloat!
    var borderWidth: CGFloat!
    var edgeCurve: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required convenience init(baseView: UIView, containingView: UIView, attributedText: NSAttributedString, fontSize: CGFloat = 17) {
        let padding = fontSize
        let triangleHeight = fontSize * 0.5
        let radius = fontSize * 1.2
        let margin = fontSize * 0.14 // margin between the baseview and balloon
        let borderWidth = fontSize * 0.25

        let edgeCurve = fontSize * 0.14 // smaller the curvier
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.attributedText = attributedText
        label.numberOfLines = 0
        let size = label.sizeThatFits(CGSize(width: containingView.frame.width-2*padding, height: containingView.frame.height-2*padding))

        self.init(frame: CGRect(x: 0, y: 0, width: size.width + 2 * padding, height: size.height + 2.5 * padding))
        label.frame = CGRect(x: padding, y: padding, width: size.width, height: size.height)

        self.triangleHeight = triangleHeight
        self.radius = radius
        self.borderWidth = borderWidth
        self.edgeCurve = edgeCurve

        self.addSubview(label)
        self.center = CGPoint(x: containingView.frame.width/2, y: containingView.frame.height - self.frame.height/2-margin)
        
        containingView.addSubview(self)
    }
    
    override func draw(_ rect: CGRect) {
        let bubble = CGRect(x: 0, y: 0, width: rect.width - radius * 2, height: rect.height - (radius * 2 + triangleHeight)).offsetBy(dx: radius, dy: radius)
        let path = UIBezierPath()
        let radius2 = radius - borderWidth // Radius adjasted for the border width
        path.addArc(withCenter: CGPoint(x: bubble.maxX, y: bubble.minY), radius: radius2, startAngle: CGFloat(-Double.pi/2), endAngle: 0, clockwise: true)
        path.addArc(withCenter: CGPoint(x: bubble.maxX, y: bubble.maxY), radius: radius2, startAngle: 0, endAngle: CGFloat(Double.pi/2), clockwise: true)
        path.addLine(to: CGPoint(x: bubble.minX + bubble.width / 2 + triangleHeight * 1.2, y: bubble.maxY + radius2))
        
        path.addQuadCurve(to: CGPoint(x: bubble.minX + bubble.width / 2, y: bubble.maxY + radius2 + triangleHeight), controlPoint: CGPoint(x: bubble.minX + bubble.width / 2 + edgeCurve, y: bubble.maxY + radius2 + edgeCurve))
        path.addQuadCurve(to: CGPoint(x: bubble.minX + bubble.width / 2 - triangleHeight * 1.2, y: bubble.maxY + radius2), controlPoint: CGPoint(x: bubble.minX + bubble.width / 2 - edgeCurve, y: bubble.maxY + radius2 + edgeCurve))

        path.addArc(withCenter: CGPoint(x: bubble.minX, y: bubble.maxY), radius: radius2, startAngle: CGFloat(Double.pi/2), endAngle: CGFloat(Double.pi), clockwise: true)
        path.addArc(withCenter: CGPoint(x: bubble.minX, y: bubble.minY), radius: radius2, startAngle: CGFloat(Double.pi), endAngle: CGFloat(-Double.pi/2), clockwise: true)
        path.close()
        
        fillColor.setFill()
        path.lineWidth = borderWidth
        path.fill()
    }
}
