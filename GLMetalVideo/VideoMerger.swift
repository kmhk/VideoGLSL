//
//  VideoMerger.swift
//  GLMetalVideo
//
//  Created by MacMaster on 7/8/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import CoreVideo

class VideoMerger {
    
    var inputTime: CFTimeInterval?
    
    var pixelBuffer: CVPixelBuffer?
    
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue
    private var computePipelineState: MTLComputePipelineState
    
    init() {
        
        // Get the default metal device.
        let metalDevice = MTLCreateSystemDefaultDevice()!
        
        // Create a command queue.
        self.commandQueue = metalDevice.makeCommandQueue()!
        
        // Create the metal library containing the shaders
        let bundle = Bundle.main
        let url = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
        
        // Create a function with a specific name.
        let function = library.makeFunction(name: "colorKernel")!
        
        // Create a compute pipeline with the above function.
        self.computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
        
        // Initialize the cache to convert the pixel buffer into a Metal texture.
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        }
        else {
            self.textureCache = textCache
        }
        
    }
    
    public func startRendering(url1: URL, url2: URL, toMP4File: URL, viewController : ViewController) {
        let asset1 = AVAsset(url: url1)
        let track1 = asset1.tracks(withMediaType: AVMediaType.video)[0]
        let asset2 = AVAsset(url: url2)
        if let assetReader = try? AVAssetReader(asset: asset1), let assetReader2 = try? AVAssetReader(asset: asset2), let assetWriter = try? AVAssetWriter(outputURL: toMP4File, fileType: AVFileType.mov) {
            let videoSettings : [String : Any] = NSDictionary(dictionaryLiteral: (kCVPixelBufferPixelFormatTypeKey, kCVPixelBufferPixelFormatTypeKey)) as! [String : Any]
            
            let track1_output = AVAssetReaderTrackOutput(track: track1, outputSettings: videoSettings)
            assetReader.add(track1_output)
            
            assetReader.startReading()
            
            let writeInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            assetWriter.add(writeInput)
            
            assetWriter.startWriting()
            
            var timestamp = 1
            
            while let buffer : CMSampleBuffer = track1_output.copyNextSampleBuffer() {
                
                if let pixelbuffer = CMSampleBufferGetImageBuffer(buffer) {
                    if let targetTexture = render(pixelBuffer: pixelbuffer, pixelBuffer2: pixelbuffer) {
                        var outPixelbuffer: CVPixelBuffer?
                        if let datas = targetTexture.buffer?.contents() {
                            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                         targetTexture.height, kCVPixelFormatType_64RGBAHalf, datas,
                                                         targetTexture.bufferBytesPerRow, nil, nil, nil, &outPixelbuffer);
                            
                            let scale = CMTimeScale(NSEC_PER_SEC)
                            let pts = CMTime(value: CMTimeValue(timestamp),
                                             timescale: scale)
                            var timingInfo = CMSampleTimingInfo(duration: CMTime.invalid,
                                                                presentationTimeStamp: pts,
                                                                decodeTimeStamp: CMTime.invalid)
                            
                            var fomartDesc : CMVideoFormatDescription
                            
                            if let sample = getCMSampleBuffer(pixelBuffer: outPixelbuffer) {
                                writeInput.append(sample)
                                timestamp += 1
                            }
                        }
                    }
                    
                    
                    print("comet")
                }
                
            }
            
            assetWriter.finishWriting(completionHandler: {() -> Void in
                viewController.openPreviewScreen(toMP4File)
            })
        }
        
    }
    
    func getCMSampleBuffer(pixelBuffer : CVPixelBuffer?) -> CMSampleBuffer? {
        
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
    
    private func render(pixelBuffer: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> MTLTexture? {
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
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer2, nil, .bgra8Unorm, width, height, 0, &cvTextureOut1)
        guard let cvTexture1 = cvTextureOut1, let inputTexture1 = CVMetalTextureGetTexture(cvTexture1) else {
            print("Failed to create metal texture")
            return nil
        }
        
        var cvTextureOut2: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut2)
        guard let cvTexture2 = cvTextureOut2 , let inputTexture2 = CVMetalTextureGetTexture(cvTexture1) else {
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
        
        // Convert the time in a metal buffer.
        var time = Float(CMTime.zero.seconds)
        computeCommandEncoder!.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        // Encode a threadgroup's execution of a compute function
        computeCommandEncoder!.dispatchThreadgroups(inputTexture.threadGroups(), threadsPerThreadgroup: inputTexture.threadGroupCount())
        
        // End the encoding of the command.
        computeCommandEncoder!.endEncoding()
        
        // Register the current drawable for rendering.
        //commandBuffer!.present(drawable)
        
        // Commit the command buffer for execution.
        commandBuffer!.commit()
        
        return inputTexture2
    }
    
    func marge(composition: AVComposition, toMP4File: URL, withCompletionHandler:(() -> Void))
    {
        if FileManager.default.fileExists(atPath: toMP4File.path) {
            try? FileManager.default.removeItem(at: toMP4File)
        }
        
        if let assetWriter = try? AVAssetWriter(outputURL: toMP4File, fileType: AVFileType.mov) {
            let videoAssetTrack = composition.tracks(withMediaType: AVMediaType.video).first
            let audioAssetTrack = composition.tracks(withMediaType: AVMediaType.audio).first
            
            let videoSettings = NSDictionary(dictionaryLiteral: (AVVideoCodecKey, AVVideoCodecH264),(AVVideoWidthKey, 1000), (AVVideoHeightKey, 750))
            
            var videoWritterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings as! [String : Any])
            
            videoWritterInput.expectsMediaDataInRealTime = true
            
            if assetWriter.canAdd(videoWritterInput) {
                assetWriter.add(videoWritterInput)
                
                assetWriter.finishWriting(completionHandler: {() -> Void in
                    
                })
            }
        }
        
    }
}

extension MTLTexture {
    
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
    
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}
