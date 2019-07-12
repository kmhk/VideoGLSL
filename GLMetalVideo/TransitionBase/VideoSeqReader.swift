//
//  VideoSeqReader.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVKit

final class VideoSeqReader {
    
    let PX_BUFFER_OPTS = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    
    let videoOutput: AVAssetReaderTrackOutput
    let reader: AVAssetReader
    
    let nominalFrameRate: Float
    
    init(asset: AVAsset) {
        
        reader = try! AVAssetReader(asset: asset)
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: PX_BUFFER_OPTS)
        
        reader.add(videoOutput)
        
        nominalFrameRate = videoTrack.nominalFrameRate
        
        reader.startReading()
        
        assert(reader.status != .failed, "reader started failed error \(reader.error)")
        
    }
    
    func next() -> CVPixelBuffer? {
        
        if let sb = videoOutput.copyNextSampleBuffer() {
            let pxbuffer = CMSampleBufferGetImageBuffer(sb)
            return pxbuffer
        }
        
        return nil
    }
    
}
