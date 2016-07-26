//
//  Helpers.swift
//  Geo Fence
//
//  Created by Julian Jans on 13/07/2016.
//  Copyright © 2016 Julian Jans. All rights reserved.
//

import UIKit
import MapKit

extension UIColor {
    
    class func randomColor(alpha: CGFloat) -> UIColor {
        let randomR:CGFloat = CGFloat(drand48())
        let randomG:CGFloat = CGFloat(drand48())
        let randomB:CGFloat = CGFloat(drand48())
        return UIColor(red: randomR, green: randomG, blue: randomB, alpha: alpha)
    }
    
    class func randomColors() -> (fill: UIColor, stroke: UIColor) {
        let randomR:CGFloat = CGFloat(drand48())
        let randomG:CGFloat = CGFloat(drand48())
        let randomB:CGFloat = CGFloat(drand48())
        return (UIColor(red: randomR, green: randomG, blue: randomB, alpha: 0.6), UIColor(red: randomR, green: randomG, blue: randomB, alpha: 0.9))
    }

}

extension Double {
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}

class GradientCircleRenderer: MKCircleRenderer {
    
    override func fillPath(path: CGPath, inContext context: CGContext) {
        let rect:CGRect = CGPathGetBoundingBox(path)
        
        CGContextAddPath(context, path);
        CGContextClip(context);
        
        let gradientLocations: [CGFloat]  = [0.8, 0.5];
        let fillColorComponents = CGColorGetComponents(fillColor!.CGColor)
        let gradientColors: [CGFloat] = [fillColorComponents[0], fillColorComponents[1], fillColorComponents[2], 0.0, fillColorComponents[0], fillColorComponents[1], fillColorComponents[2], fillColorComponents[3]];
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let gradient = CGGradientCreateWithColorComponents(colorSpace, gradientColors, gradientLocations, 2);
        let gradientCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        let gradientRadius = min(rect.size.width, rect.size.height) / 2;
        
        CGContextDrawRadialGradient(context, gradient, gradientCenter, 0, gradientCenter, gradientRadius, .DrawsAfterEndLocation);
    }
}