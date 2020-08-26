//
//  CALayer+pause-resume.swift
//  ClockWipeSwift
//
//  Created by Duncan Champney on 8/25/20.
/*
Copyright <2020> <Duncan Champney>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//  Credit to Rand, from Stack Overflow, for the basis of this extension
//  see https://stackoverflow.com/a/59079995/205185

import UIKit
import CoreGraphics

import Foundation

extension CALayer
{

    func isPaused() -> Bool {
        return speed == 0
    }

    private func internalPause(_ pause: Bool) {
        if pause {
            let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
            speed = 0.0
            timeOffset = pausedTime
        } else {
            let pausedTime = timeOffset
            speed = 1.0
            timeOffset = 0.0
            beginTime = 0.0
            let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            beginTime = timeSincePause
        }
    }


    func pauseAnimation(_ pause: Bool) {
        if pause != isPaused()  {
            internalPause(pause)
        }
    }

    func pauseOrResumeAnimation() {
        internalPause(isPaused())
    }
}
