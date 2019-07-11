//
//  transition_glitchmemories.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/11/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>
#include <metal_geometric>

using namespace metal;

kernel void transition_glitchmemories(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                      texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                      texture2d<float, access::write> outTexture [[ texture(2) ]],
                                      device const float *progress [[ buffer(0) ]],
                                      uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 block = floor(ngid.xy / float2(16));
    float2 uv_noise = block / float2(64);
    uv_noise += floor(float2(prog) * float2(1200.0, 3500.0)) / float2(64);
    float2 dist = prog > 0.0 ? (fract(uv_noise) - 0.5) * 0.3 *(1.0 -prog) : float2(0.0);
    float2 red = ngid + dist * 0.2;
    uint2 new_red = uint2(red.x * inTexture.get_width(), red.y * inTexture.get_height());
    float2 green = ngid + dist * .3;
    uint2 new_green = uint2(green.x * inTexture.get_width(), green.y * inTexture.get_height());
    float2 blue = ngid + dist * .5;
    uint2 new_blue = uint2(blue.x * inTexture.get_width(), blue.y * inTexture.get_height());
    
    outTexture.write(float4(mix(inTexture2.read(new_red), inTexture.read(new_red), prog).r,
                            mix(inTexture2.read(new_green), inTexture.read(new_green), prog).g,
                            mix(inTexture2.read(new_blue), inTexture.read(new_blue), prog).b,1.0), gid);
}

