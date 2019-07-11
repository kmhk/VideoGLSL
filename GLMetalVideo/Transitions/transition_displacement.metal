//
//  transition_displacement.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/11/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>

using namespace metal;

kernel void transition_displacement(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                    texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    texture2d<float, access::read> samplerTex [[ texture(3) ]],
                                    device const float *progress [[ buffer(0) ]],
                                    uint2 gid [[ thread_position_in_grid ]])
{
    sampler displacementMap;
    float strength = 0.0005;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float displacement = secOrig.r * strength;
    
    float2 newFrom = float2(ngid.x + prog * displacement, ngid.y);
    newFrom.x *= inTexture.get_width();
    newFrom.y *= inTexture.get_height();
    
    float2 newTo = float2(ngid.x - (1.0 - prog) * displacement, ngid.y);
    newTo.x *= inTexture.get_width();
    newTo.y *= inTexture.get_height();
    
    uint2 uvFrom = uint2(newFrom);
    uint2 uvTo = uint2(newTo);
    
    outTexture.write(mix(
                         inTexture2.read(uvTo),
                         inTexture.read(uvFrom),
                         prog
                         ), gid);
}

