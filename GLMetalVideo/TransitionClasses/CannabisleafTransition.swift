//
//  CannabisleafTransition.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVKit
import MetalKit

final class CannabisleafScrawler : TransitionRenderer {
    
    init(asset: AVAsset, asset1: AVAsset) {
        super.init(asset: asset, asset1: asset1, function: "transition_cannabisleaf")
        
    }
    
}
