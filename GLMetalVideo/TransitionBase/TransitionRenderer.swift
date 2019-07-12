//
//  VideoCompositionRender.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVKit
import MetalKit

public class TransitionRenderer {
    
    let header_reader: VideoSeqReader
    let tail_reader: VideoSeqReader
    
    let header_duration : CMTime
    let tail_duration : CMTime
    
    var presentationTime : CMTime = CMTime.zero
    
    var frameCount = 0
    
    var transtionSecondes : Double = 5
    
    var transtion_function = "transition_colorphase"
    
    var inputTime: CFTimeInterval?
    
    var pixelBuffer: CVPixelBuffer?
    
    var textureCache: CVMetalTextureCache?
    var commandQueue: MTLCommandQueue
    var computePipelineState: MTLComputePipelineState
    
    init(asset: AVAsset, asset1: AVAsset, function: String) {
        header_reader = VideoSeqReader(asset: asset)
        tail_reader = VideoSeqReader(asset: asset1)
        transtion_function = function
        
        header_duration = asset.duration
        tail_duration = asset1.duration
        
        // Get the default metal device.
        let metalDevice = MTLCreateSystemDefaultDevice()!
        
        // Create a command queue.
        commandQueue = metalDevice.makeCommandQueue()!
        
        // Create the metal library containing the shaders
        let bundle = Bundle.main
        let url = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
        
        // Create a function with a specific name.
        let function = library.makeFunction(name: transtion_function)!
        
        // Create a compute pipeline with the above function.
        computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
        
        // Initialize the cache to convert the pixel buffer into a Metal texture.
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        }
        else {
            textureCache = textCache
        }
        
    }
    
    public func initFunction() {
        
    }
    
    func next() -> (CVPixelBuffer, CMTime)? {
        
        if presentationTime.seconds < header_duration.seconds - transtionSecondes {
            
            if let frame = header_reader.next() {
                
                let frameRate = header_reader.nominalFrameRate
                presentationTime = CMTimeMake(value: Int64(frameCount * 600), timescale: Int32(600 * frameRate))
                //let image = frame.filterWith(filters: filters)
                
                print("comet")
                frameCount += 1
                
                return (frame, presentationTime)
            }
            
            
        } else if presentationTime.seconds >= header_duration.seconds - transtionSecondes && presentationTime.seconds < header_duration.seconds - 0.3 {
            
            if let frame = header_reader.next(), let frame1 = tail_reader.next() {
                
                let frameRate = header_reader.nominalFrameRate
                presentationTime = CMTimeMake(value: Int64(frameCount * 600), timescale: Int32(600 * frameRate))
                //let image = frame.filterWith(filters: filters)
                let progress = (header_duration.seconds - presentationTime.seconds) / transtionSecondes
                if let targetTexture = render(pixelBuffer: frame, pixelBuffer2: frame1, progress: Float(progress)) {
                    var outPixelbuffer: CVPixelBuffer?
                    if let datas = targetTexture.buffer?.contents() {
                        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                     targetTexture.height, kCVPixelFormatType_64RGBAHalf, datas,
                                                     targetTexture.bufferBytesPerRow, nil, nil, nil, &outPixelbuffer);
                        if outPixelbuffer != nil {
                            frameCount += 1
                            
                            return (outPixelbuffer!, presentationTime)
                        }
                        
                    }
                }
                
                
                print("comet")
                frameCount += 1
                
                return (frame, presentationTime)
            }
            
        } else {
            
            if let frame = tail_reader.next() {
                
                let frameRate = tail_reader.nominalFrameRate
                presentationTime = CMTimeMake(value: Int64(frameCount * 600), timescale: Int32(600 * frameRate))
                //let image = frame.filterWith(filters: filters)
                
                print("comet")
                frameCount += 1
                
                return (frame, presentationTime)
            }
            
            
        }
        
        return nil
        
    }
    
    public func render(pixelBuffer: CVPixelBuffer, pixelBuffer2: CVPixelBuffer, progress: Float) -> MTLTexture? {
        // here the metal code
        // Check if the pixel buffer exists
        
        // Get width and height for the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Converts the pixel buffer in a Metal texture.
        var cvTextureOut: CVMetalTexture?
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create metal texture")
            return nil
        }
        
        // Get width and height for the pixel buffer
        let width1 = CVPixelBufferGetWidth(pixelBuffer2)
        let height1 = CVPixelBufferGetHeight(pixelBuffer2)
        
        // Converts the pixel buffer in a Metal texture.
        var cvTextureOut1: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer2, nil, .bgra8Unorm, width1, height1, 0, &cvTextureOut1)
        guard let cvTexture1 = cvTextureOut1, let inputTexture1 = CVMetalTextureGetTexture(cvTexture1) else {
            print("Failed to create metal texture")
            return nil
        }
        
        var cvTextureOut2: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut2)
        guard let cvTexture2 = cvTextureOut2 , let inputTexture2 = CVMetalTextureGetTexture(cvTexture2) else {
            print("Failed to create metal texture")
            return nil
        }
        
        // Check if Core Animation provided a drawable.
        
        // Create a command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // Create a compute command encoder.
        let computeCommandEncoder = commandBuffer!.makeComputeCommandEncoder()
        
        // Set the compute pipeline state for the command encoder.
        computeCommandEncoder!.setComputePipelineState(computePipelineState)
        
        // Set the input and output textures for the compute shader.
        computeCommandEncoder!.setTexture(inputTexture, index: 0)
        computeCommandEncoder!.setTexture(inputTexture1, index: 1)
        computeCommandEncoder!.setTexture(inputTexture2, index: 2)
        
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        
        let threadGroups: MTLSize = {
            MTLSizeMake(Int(width) / threadGroupCount.width, Int(height) / threadGroupCount.height, 1)
        }()
        // Convert the time in a metal buffer.
        var time = Float(progress)
        computeCommandEncoder!.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        // Encode a threadgroup's execution of a compute function
        computeCommandEncoder!.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        // End the encoding of the command.
        computeCommandEncoder!.endEncoding()
        
        // Register the current drawable for rendering.
        //commandBuffer!.present(drawable)
        
        // Commit the command buffer for execution.
        commandBuffer!.commit()
        commandBuffer!.waitUntilCompleted()
        
        return inputTexture2
    }
    
    public func getCMSampleBuffer(pixelBuffer : CVPixelBuffer?) -> CMSampleBuffer? {
        
        if pixelBuffer == nil {
            return nil
        }
        
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = CMTime.invalid
        
        
        var formatDesc: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &formatDesc)
        
        var sampleBuffer: CMSampleBuffer? = nil
        
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer!,
                                                 formatDescription: formatDesc!,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuffer);
        
        return sampleBuffer!
    }
    
}
