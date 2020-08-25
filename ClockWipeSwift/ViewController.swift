//
//  ViewController.swift
//  ClockWipeSwift
//
//  Created by Duncan Champney on 8/24/20.
//  Copyright © 2020 Duncan Champney. All rights reserved.
//

import UIKit
import CoreGraphics

typealias AnimationCompletion = (Bool) -> Void



class ViewController: UIViewController {


    @IBOutlet weak var animateButton: UIButton!

    @IBOutlet weak var imageView: UIImageView!


    //Set to true to start with the image hidden, and reveal it during the animation.
    //Set to false to begin with the image visble, and animate hiding it
    var reveal = false
    var useCGPaths = true

    let animationCompletionKey = "animationCompletion"
    lazy var shapeLayer = CAShapeLayer()

    //If we get resized, update the size of the image view's shape layer
    override func viewDidLayoutSubviews() {
        shapeLayer.frame = imageView.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
    }


    @IBAction func handleAnimateButton(_ sender: Any) {



        //MARK: - Set up the shape layer as a mask layer
        shapeLayer.path = nil
        animateButton.isEnabled = false  //Disable the animate button while the animation is running

        let maskHeight = imageView.bounds.height
        let maskWidth = imageView.bounds.width

        let centerPoint = CGPoint( x: maskWidth/2, y: maskHeight/2) //Calculate the centerpoint of the image view

        let radius = (maskWidth * maskWidth + maskHeight * maskHeight).squareRoot()/2.0
        shapeLayer.fillColor = UIColor.clear.cgColor     //We want the mask filled with a clear color so the path stroke draws opaque against a clear background
        shapeLayer.strokeColor = UIColor.black.cgColor

        //Make the line width be the 1/2 of the center-to-corner distance,
        //so the stroked line completely fills the whole bounding rectangle
        shapeLayer.lineWidth = radius


        //MARK: - Add a full-circle arc that starts at the top center of the rect ("north") to the mask CAShapeLayer's path

        let startAngle = reveal ? -0.5 * CGFloat.pi : 1.5 * CGFloat.pi
        let endAngle = reveal ? 1.5 * CGFloat.pi : -0.5 * CGFloat.pi
        if useCGPaths {
            //Create an empty CGPath
            let path = CGMutablePath()

            //Add an arc that starts at 3π/2 (straight up) and ends at -π/2 (straight up, but a full turn clockwise
            path.addArc(center: centerPoint,
                        radius: radius/2,
                        startAngle: startAngle ,
                        endAngle: endAngle,
                        clockwise: !reveal)
            shapeLayer.path = path
            imageView.layer.mask = shapeLayer    //Install the shape view as the mask layer for the image view.
        } else {
            let path = UIBezierPath(arcCenter: centerPoint,
                                    radius: radius/2,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: reveal)
            path.lineWidth = radius
            shapeLayer.path = path.cgPath
            imageView.layer.mask = shapeLayer    //Install the shape view as the mask layer for the image view.
//            imageView.layer.addSublayer(shapeLayer)    //Install the shape view as the mask layer for the image view.
        }
        //For a reveal animation, start the animation with the path empty. (mask blank, which fully hides the image underneath.)
        if reveal {
            shapeLayer.strokeEnd = 0;
        } else {
            shapeLayer.strokeEnd = 1.0;
        }



        //MARK: - Create the animation
        let clockWipe = CABasicAnimation(keyPath: "strokeEnd")  //Create an animation of the shape layer's strokeEnd property

        clockWipe.duration = 2
        clockWipe.autoreverses = true

        if reveal {
            //For a reveal animation, animate the stroke end from 1 to zero
            clockWipe.toValue = 1;
        } else {
            //Else this is a
            clockWipe.toValue = 0  ;
        }


        //Make the animation slow to a stop before reversing - optional, but makes it easier to see the image fully disappear
        clockWipe.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        //Create a closure to be executed when the animation is complete.
        let animationCompletion: AnimationCompletion = { finished in
            guard finished else { return }
            //Remove the shape layer once the animation is complete
            //(if the view gets resized the mask layer's shape won't fit the new view size.
            self.imageView.layer.mask = nil
            self.shapeLayer.removeFromSuperlayer()  //This is only needed if you add the shape layer as a sublayer rather than a mask layer
            self.animateButton.isEnabled = true //re-enable the animate button
            print("Animation complete!")
        }

        //Attach the closure to the animation
        clockWipe.setValue(animationCompletion, forKey: animationCompletionKey)

        //Set up the view controller as the animation's delegate so the animationDidStop(_, finished:) method gets called when the animation is complete
        clockWipe.delegate = self

        //Finally, add the animation to the shape layer
        shapeLayer.add(clockWipe, forKey: "clockWipe")
    }
}

extension ViewController: CAAnimationDelegate {
    func animationDidStop(_ animation: CAAnimation, finished: Bool) {

        //See if the animation has an attached AnimationCompletion closure
        guard let completion = animation.value(forKey: animationCompletionKey) as? AnimationCompletion else { return }
        completion(finished)
    }
}

