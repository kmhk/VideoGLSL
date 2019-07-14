//
//  ColorPhaseTransition.swift
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import MetalKit
import AVKit

final class ColorPhaseTransition : TransitionRenderer {
    
    var fromStep : PixelPoint = PixelPoint(red: 0.0, green: 0.2, blue: 0.4, alpha: 0.0); //(0.0, 0.2, 0.4, 0.0);
    var toStep : PixelPoint = PixelPoint(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0); //(0.6, 0.8, 1.0, 1.0);
    var shadow_height : Float = 0.075; // = 0.075
    var bounces : Float = 3.0; // = 3.0
    	
    init(asset: AVAsset, asset1: AVAsset) {
        super.init(asset: asset, asset1: asset1, function: "transition_colorphase")
        
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
        var from_a = Float(self.fromStep.r)
        computeCommandEncoder!.setBytes(&from_a, length: MemoryLayout<Float>.size, index: 1)
        var from_g = Float(self.fromStep.g)
        computeCommandEncoder!.setBytes(&from_g, length: MemoryLayout<Float>.size, index: 2)
        var from_b = Float(self.fromStep.b)
        computeCommandEncoder!.setBytes(&from_b, length: MemoryLayout<Float>.size, index: 3)
        var from_alpha = Float(self.fromStep.alpha)
        computeCommandEncoder!.setBytes(&from_alpha, length: MemoryLayout<Float>.size, index: 4)
        var to_a = Float(self.toStep.r)
        computeCommandEncoder!.setBytes(&to_a, length: MemoryLayout<Float>.size, index: 5)
        var to_g = Float(self.toStep.g)
        computeCommandEncoder!.setBytes(&to_g, length: MemoryLayout<Float>.size, index: 6)
        var to_b = Float(self.toStep.b)
        computeCommandEncoder!.setBytes(&to_b, length: MemoryLayout<Float>.size, index: 7)
        var to_alpha = Float(self.toStep.alpha)
        computeCommandEncoder!.setBytes(&to_alpha, length: MemoryLayout<Float>.size, index: 8)
        
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
