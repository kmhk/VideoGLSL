//
//  GridFlipTransition.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/15/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


import Foundation
import MetalKit
import AVKit

final class GridFlipTransition : TransitionRenderer {
    
    var size_w = 4
    var size_h = 4
    var pause = 0.1
    var dividerWidth = 0.05
    var bgcolor = PixelPoint(red: 0, green: 0, blue: 0, alpha: 1.0)
    var randomness = 0.1
    
    init(asset: AVAsset, asset1: AVAsset) {
        super.init(asset: asset, asset1: asset1, function: "transition_grid_flip")
        
    }
    
    public override func render(pixelBuffer: CVPixelBuffer, pixelBuffer2: CVPixelBuffer, progress: Float) -> MTLTexture? {
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
        var var_1 = Int(self.size_w)
        computeCommandEncoder!.setBytes(&var_1, length: MemoryLayout<Int>.size, index: 1)
        var var_2 = Int(self.size_h)
        computeCommandEncoder!.setBytes(&var_2, length: MemoryLayout<Int>.size, index: 2)
        var var_3 = Float(self.pause)
        computeCommandEncoder!.setBytes(&var_3, length: MemoryLayout<Float>.size, index: 3)
        var var_4 = Float(self.dividerWidth)
        computeCommandEncoder!.setBytes(&var_4, length: MemoryLayout<Float>.size, index: 4)
        var var_5 = Float(self.bgcolor.r)
        computeCommandEncoder!.setBytes(&var_5, length: MemoryLayout<Float>.size, index: 5)
        var var_6 = Float(self.bgcolor.g)
        computeCommandEncoder!.setBytes(&var_6, length: MemoryLayout<Float>.size, index: 6)
        var var_7 = Float(self.bgcolor.b)
        computeCommandEncoder!.setBytes(&var_7, length: MemoryLayout<Float>.size, index: 7)
        var var_8 = Float(self.bgcolor.alpha)
        computeCommandEncoder!.setBytes(&var_8, length: MemoryLayout<Float>.size, index: 8)
        var var_9 = Float(self.randomness)
        computeCommandEncoder!.setBytes(&var_9, length: MemoryLayout<Float>.size, index: 9)
        
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
}
