//
//  transtion_directional.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

kernel void transition_directional(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   device const float *dx [[ buffer(1) ]],
                                   device const float *dy [[ buffer(2) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    float2 direction = float2(*dx, *dy); // = float2(0.0, 1.0)
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 p = ngid + prog * sign(direction);
    float2 f = fract(p);
    
    outTexture.write(mix(
               inTexture.read(toUint2(f, inTexture)),
               inTexture2.read(toUint2(f, inTexture2)),
               step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0)
               ), gid);
    
}
