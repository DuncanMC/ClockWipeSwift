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

    let animationCompletionKey = "animationCompletion"
    lazy var maskLayer = CAShapeLayer()

    //If we get resized, update the size of the image view's mask layer
    override func viewDidLayoutSubviews() {
        maskLayer.frame = imageView.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
    }


    @IBAction func handleAnimateButton(_ sender: Any) {

        //MARK: - Set up the mask layer
        maskLayer.path = nil
        animateButton.isEnabled = false  //Disable the animate button while the animation is running

        let maskHeight = imageView.bounds.height
        let maskWidth = imageView.bounds.width

        let centerPoint = CGPoint( x: maskWidth/2, y: maskHeight/2) //Calculate the centerpoint of the image view

        let radius = (maskWidth * maskWidth + maskHeight * maskHeight).squareRoot()/2.0
        maskLayer.fillColor = UIColor.clear.cgColor     //We want the mask filled with a clear color so the path stroke draws opaque against a clear background
        maskLayer.strokeColor = UIColor.black.cgColor

        maskLayer.lineWidth = radius    //Make the line width be the 1/2 of the center-to-corner distance,
        //so the stroked line completely fills the whole bounding rectangle

        //MARK: - Add a full-circle arc that starts at the top center of the rect ("north") to the mask CAShapeLayer's path

        //Create an empty CGPath
        let path = CGMutablePath()

        //Add an arc that starts at 3π/2 (straight up) and ends at -π/2 (straight up, but a full turn clockwise
        path.addArc(center: centerPoint,
                    radius: radius/2,
                    startAngle: CGFloat.pi * 1.5,
                    endAngle: -CGFloat.pi/2.0 ,
                    clockwise: true)
        maskLayer.path = path

        maskLayer.strokeEnd = 1.0;  //Start the animation fully stroked. (mask fully opaque, which fully reveals the image underneath.)

        imageView.layer.mask = maskLayer    //Install the shape view as the mask layer for the image view.


        //MARK: - Create the animation
        let clockWipe = CABasicAnimation(keyPath: "strokeEnd")  //Create an animation of the shape layer's strokeEnd property

        clockWipe.duration = 2
        clockWipe.autoreverses = true

        clockWipe.toValue = 0   //Animate the shape layer's strokeEnd path from 1.0 to 0.0

        //Make the animation slow to a stop before reversing - optional, but makes it easier to see the image fully disappear
        clockWipe.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

        //Create a closure to be executed when the animation is complete.
        let animationCompletion: AnimationCompletion = { finished in
            guard finished else { return }
            //Remove the mask layer once the animation is complete
            //(if the view gets resized the mask layer's shape won't fit the new view size.
            self.imageView.layer.mask = nil
            self.animateButton.isEnabled = true //re-enable the animate button
            print("Animation complete!")
        }

        //Attach the closure to the animation
        clockWipe.setValue(animationCompletion, forKey: animationCompletionKey)

        //Set up the view controller as the animation's delegate so the animationDidStop(_, finished:) method gets called when the animation is complete
        clockWipe.delegate = self

        //Finally, add the animation to the mask layer
        maskLayer.add(clockWipe, forKey: "clockWipe")
    }

}

extension ViewController: CAAnimationDelegate {
    func animationDidStop(_ animation: CAAnimation, finished: Bool) {

        //See if the animation has an attached AnimationCompletion closure
        guard let completion = animation.value(forKey: animationCompletionKey) as? AnimationCompletion else { return }
        completion(finished)
    }
}

