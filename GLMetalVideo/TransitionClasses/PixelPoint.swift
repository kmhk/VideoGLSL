//
//  PixelPoint.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation

final class PixelPoint {
    var r : Float
    var g : Float
    var b : Float
    var alpha : Float

    init(red: Float, green: Float, blue: Float, alpha: Float) {
        r = red
        g = green
        b = blue
        self.alpha = alpha
    }
}

final class VecPoint {
    var x : Float
    var y : Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}
