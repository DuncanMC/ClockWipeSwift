//
//  ViewController.swift
//  ClockWipeSwift
//
//  Created by Duncan Champney on 8/24/20.
/*
Copyright <2020> <Duncan Champney>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import UIKit
import CoreGraphics

typealias AnimationCompletion = (Bool) -> Void



class ViewController: UIViewController {


    @IBOutlet weak var animateButton: UIButton!

    @IBOutlet weak var pauseResumeButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rotateCCWSwitch: UISwitch!
    @IBOutlet weak var revealAnimationSwitch: UISwitch!


    //Set to true to start with the image hidden, and reveal it during the animation.
    //Set to false to begin with the image visble, and animate hiding it
    var reveal = false
    var useCGPaths = true

    var animateCounterclockwise = false

    let animationCompletionKey = "animationCompletion"
    lazy var shapeLayer = CAShapeLayer()

    //If we get resized, update the size of the image view's shape layer
    override func viewDidLayoutSubviews() {
        shapeLayer.frame = imageView.bounds
    }

    var animationPaused: Bool = false {
        didSet {
            configurePauseResumeButton()
            imageView.layer.pauseAnimation(animationPaused)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
        animationPaused = false
        pauseResumeButton.isEnabled = false
    }

    @IBAction func handleRotateCCWSwitch(_ sender: Any) {
        animateCounterclockwise = rotateCCWSwitch.isOn
    }

    @IBAction func handleRevealAnimationSwitch(_ sender: Any) {
        reveal = revealAnimationSwitch.isOn
    }
    @IBAction func handleAnimateButton(_ sender: Any) {
        //MARK: - Set up the shape layer as a mask layer
        shapeLayer.path = nil
        animateButton.isEnabled = false  //Disable the animate button while the animation is running
        pauseResumeButton.isEnabled = true

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
        let direction = animateCounterclockwise ? reveal : !reveal
        let startAngle = direction ? 1.5 * CGFloat.pi : -0.5 * CGFloat.pi
        let endAngle = direction ? -0.5 * CGFloat.pi : 1.5 * CGFloat.pi
        if useCGPaths {
            //Create an empty CGPath
            let path = CGMutablePath()

            //Add an arc that starts at 3π/2 (straight up) and ends at -π/2 (straight up, but a full turn clockwise
            path.addArc(center: centerPoint,
                        radius: radius/2,
                        startAngle: startAngle ,
                        endAngle: endAngle,
                        clockwise: direction)
            shapeLayer.path = path

        } else {
            let path = UIBezierPath(arcCenter: centerPoint,
                                    radius: radius/2,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: reveal)
            path.lineWidth = radius
            shapeLayer.path = path.cgPath
        }



        //Disable implicit animations before changing strokeEnd to avoid animating the change.
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        //For a reveal animation, start the animation with the path empty. (mask blank, which fully hides the image underneath.)
        if reveal {
            shapeLayer.strokeEnd = 0
        } else {
            shapeLayer.strokeEnd = 1.0
        }
        CATransaction.commit()
        imageView.layer.mask = shapeLayer    //Install the shape view as the mask layer for the image view.

        //MARK: - Create the animation
        let clockWipe = CABasicAnimation(keyPath: "strokeEnd")  //Create an animation of the shape layer's strokeEnd property

        clockWipe.duration = 2
        clockWipe.autoreverses = true

        if reveal {
            //For a reveal animation, animate the stroke end from 1 to zero
            clockWipe.toValue = 1
        } else {
            //Else this is a
            clockWipe.toValue = 0
        }


        //Make the animation slow to a stop before reversing - optional, but makes it easier to see the image fully disappear
        clockWipe.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        //Create a closure to be executed when the animation is complete.
        let animationCompletion: AnimationCompletion = { finished in
            guard finished else { return }
            //Remove the shape layer once the animation is complete
            //(if the view gets resized the mask layer's shape won't fit the new view size.
            self.shapeLayer.path = nil
            self.imageView.layer.mask = nil

            //self.shapeLayer.removeFromSuperlayer()  //This is only needed if you add the shape layer as a sublayer rather than a mask layer
            self.animateButton.isEnabled = true //re-enable the animate button
            self.pauseResumeButton.isEnabled = false
            print("Animation complete!")
        }

        //Attach the closure to the animation
        clockWipe.setValue(animationCompletion, forKey: animationCompletionKey)

        //Set up the view controller as the animation's delegate so the animationDidStop(_, finished:) method gets called when the animation is complete
        clockWipe.delegate = self

        //Finally, add the animation to the shape layer
        shapeLayer.add(clockWipe, forKey: "clockWipe")
    }
    @IBAction func handlePauseResumeButton(_ sender: Any) {
        animationPaused = !animationPaused
    }

    func configurePauseResumeButton() {
        let pauseString = NSLocalizedString("Pause", comment: "Pause button title")
        let resumeString = NSLocalizedString("Resume", comment: "Pause button title")
        let buttonTitle = animationPaused ? resumeString : pauseString
        pauseResumeButton.setTitle(buttonTitle, for: .normal)
    }
}

extension ViewController: CAAnimationDelegate {
    func animationDidStop(_ animation: CAAnimation, finished: Bool) {

        //See if the animation has an attached AnimationCompletion closure
        guard let completion = animation.value(forKey: animationCompletionKey) as? AnimationCompletion else { return }
        completion(finished)
    }
}

