//
//  VideoMerger.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/8/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVFoundation

class VideoMerger {
    var videoUrl1 : URL
    var videoUrl2 : URL
    
    var exportURL : URL
    
    var callback : ViewController
    
    var transtionSecondes : Double = 5
    
    var transtion_function = "transition_colorphase"
    
    init(url1: URL, url2: URL, export: URL, vc : ViewController) {
        videoUrl1 = url1
        videoUrl2 = url2
        
        exportURL = export
        callback = vc
    }
    
    func startRendering() {
        var transition : TransitionRenderer
        if transtion_function == "transition_angular" {
            transition = AngularTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_bouncer" {
            transition = BouncerTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_bow_tie_horizontal" {
            transition = BowTieHorizontal(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_bow_tie_vertical" {
            transition = BowTieVertical(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_burn" {
            transition = BurnTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_butterfly_wave_scrawler" {
            transition = ButterflyWavesScrawler(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_cannabisleaf" {
            transition = CannabisleafScrawler(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_displacement" {
            transition = DisplacementTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_linearblur" {
            transition = LinearBlurTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else if transtion_function == "transition_wind" {
            transition = WindTransition(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2))
        } else {
            transition = TransitionRenderer(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2), function: transtion_function)
        }
        
        transition.transtionSecondes = transtionSecondes
        
        let writer : VideoSeqWriter = VideoSeqWriter(outputFileURL: exportURL, render: transition, videoSize: CGSize(width: 1280, height: 720))
        
        writer.startRender(vc: callback, url: exportURL)
    }
}


