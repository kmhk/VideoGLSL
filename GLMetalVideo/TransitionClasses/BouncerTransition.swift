//
//  BouncerTransition.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


import Foundation
import MetalKit
import AVKit

final class BouncerTransition : TransitionRenderer {
    
    var shadow_colour : PixelPoint = PixelPoint(red: 0, green: 0, blue: 0, alpha: 0.6); // = vec4(0.,0.,0.,.6)
    var shadow_height : Float = 0.075; // = 0.075
    var bounces : Float = 3.0; // = 3.0
    
    init(asset: AVAsset, asset1: AVAsset) {
        super.init(asset: asset, asset1: asset1, function: "transition_bouncer")
        
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
        var shadow_a = Float(self.shadow_colour.r)
        computeCommandEncoder!.setBytes(&shadow_a, length: MemoryLayout<Float>.size, index: 1)
        var shadow_g = Float(self.shadow_colour.g)
        computeCommandEncoder!.setBytes(&shadow_g, length: MemoryLayout<Float>.size, index: 2)
        var shadow_b = Float(self.shadow_colour.b)
        computeCommandEncoder!.setBytes(&shadow_b, length: MemoryLayout<Float>.size, index: 3)
        var shadow_alpha = Float(self.shadow_colour.alpha)
        computeCommandEncoder!.setBytes(&shadow_alpha, length: MemoryLayout<Float>.size, index: 4)
        var shadow_height = Float(self.shadow_height)
        computeCommandEncoder!.setBytes(&shadow_height, length: MemoryLayout<Float>.size, index: 5)
        var shadow_bounces = Float(self.bounces)
        computeCommandEncoder!.setBytes(&shadow_bounces, length: MemoryLayout<Float>.size, index: 6)
        
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
