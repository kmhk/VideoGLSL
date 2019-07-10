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
        
        let composition : VideoCompositionRender = VideoCompositionRender(asset: AVAsset(url: videoUrl1), asset1: AVAsset(url: videoUrl2), function: transtion_function)
        
        composition.transtionSecondes = transtionSecondes
        
        let writer : VideoWriter = VideoWriter(outputFileURL: exportURL, render: composition, videoSize: CGSize(width: 1280, height: 720))
        
        writer.startRender(vc: callback, url: exportURL)
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


final class VideoSeqReader {
    
    let PX_BUFFER_OPTS = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    
    let videoOutput: AVAssetReaderTrackOutput
    let reader: AVAssetReader
    
    let nominalFrameRate: Float
    
    init(asset: AVAsset) {
        
        var error: NSError?
        reader = try! AVAssetReader(asset: asset)
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0] as! AVAssetTrack
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

final class VideoWriter {
    
    let glContext : EAGLContext
    let ciContext : CIContext
    let writer : AVAssetWriter
    
    class func setupWriter(outputFileURL: URL) -> AVAssetWriter {
        let fileManager = FileManager.default
        
        let outputFileExists = fileManager.fileExists(atPath: outputFileURL.path)
        if outputFileExists {
            try? fileManager.removeItem(at: outputFileURL)
        }
        
        var error : NSError?
        let writer = try! AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mp4)
        assert(error == nil, "init video writer should not failed: \(error)")
        
        return writer
    }
    
    let videoSize: CGSize
    
    var videoWidth : CGFloat {
        return videoSize.width
    }
    
    var videoHeight : CGFloat {
        return videoSize.height
    }
    
    var videoOutputSettings : [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight
        ]
    }
    
    var sourcePixelBufferAttributes: [String: Any] {
        return [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
            String(kCVPixelBufferWidthKey): videoWidth,
            String(kCVPixelBufferHeightKey): videoHeight
        ]
    }
    
    var videoInput: AVAssetWriterInput!
    var writerInputAdapater: AVAssetWriterInputPixelBufferAdaptor!
    
    let render: VideoCompositionRender
    
    // create an YMVideoWriter will remove the file specified at outputFileURL if the file exists
    init(outputFileURL: URL, render: VideoCompositionRender, videoSize: CGSize = CGSize(width: 640.0, height: 640.0)) {
        
        self.render = render
        self.videoSize = videoSize
        
        glContext = EAGLContext(api: .openGLES2)!
        ciContext = CIContext(eaglContext: glContext)
        writer = VideoWriter.setupWriter(outputFileURL: outputFileURL)
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        writer.add(videoInput)
        
        writerInputAdapater = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        
    }
    
    
    private func finishWriting(completion: @escaping () -> ()) {
        videoInput.markAsFinished()
        writer.endSession(atSourceTime: lastTime)
        writer.finishWriting(completionHandler: completion)
    }
    
    private var lastTime: CMTime = CMTime.zero
    
    //private var inputQueue = dispatch_queue_create("writequeue.kaipai.tv", DISPATCH_QUEUE_SERIAL)
    
    // write image in CIContext, may failed if no available space
    private func write(buffer: CVPixelBuffer, withPresentationTime time: CMTime) {
        lastTime = time
        
        print("write image at time \(CMTimeGetSeconds(time))")
        
        writerInputAdapater.append(buffer, withPresentationTime: time)
    }
    
    func startRender(vc: ViewController, url : URL) {
        
        videoInput.requestMediaDataWhenReady(on: DispatchQueue.main, using: { [self]() -> Void in
            
            while self.videoInput.isReadyForMoreMediaData {
                
                if let (frame, time) =  self.render.next() {
                    self.write(buffer: frame, withPresentationTime: time)
                } else {
                    self.finishWriting(completion: { () -> () in
                        print("finish writing")
                        vc.openPreviewScreen(url)
                    })
                    break
                }
                
            }
            
        })
        
    }
    
}

final class VideoCompositionRender {
    
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
    
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue
    private var computePipelineState: MTLComputePipelineState
    
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
                var progress = (header_duration.seconds - presentationTime.seconds) / transtionSecondes
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
    
    private func render(pixelBuffer: CVPixelBuffer, pixelBuffer2: CVPixelBuffer, progress: Float) -> MTLTexture? {
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
        
        var threadGroups: MTLSize = {
            MTLSizeMake(Int(1280) / threadGroupCount.width, Int(720) / threadGroupCount.height, 1)
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
    
    
}

