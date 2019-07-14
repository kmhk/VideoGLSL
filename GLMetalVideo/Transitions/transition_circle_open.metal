//
//  transition_circle_open.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

kernel void transition_circle_open(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *smooth [[ buffer(1) ]],
                                   device const bool *open [[ buffer(2) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float smoothness = *smooth; // = 0.3
    bool opening = *open; // = true
    
    const float2 center = float2(0.5, 0.5);
    const float SQRT_2 = 1.414213562373;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float x = opening ? prog : 1.-prog;
    float m = smoothstep(-smoothness, 0.0, SQRT_2*distance(center, ngid) - x*(1.+smoothness));
    outTexture.write(mix(secOrig, orig, opening ? 1.-m : m), gid);
    
}
