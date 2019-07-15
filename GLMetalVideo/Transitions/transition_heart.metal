//
//  transition_heart.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/15/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


float inHeart (float2 p1, float2 center, float size) {
    float2 p = float2(p1.x, 1.0 - p1.y);
    if (size==0.0) return 0.0;
    float2 o = (p-center)/(1.6*size);
    float a = o.x*o.x+o.y*o.y-0.3;
    return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
}

kernel void transition_heart(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                      texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                      texture2d<float, access::write> outTexture [[ texture(2) ]],
                                      device const float *prog [[ buffer(0) ]],
                                      uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 uv = float2(gid);
    float progress = *prog;
    
    uv.x /= inTexture.get_width();
    uv.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    outTexture.write(mix(
               secOrig,
               orig,
               inHeart(uv, float2(0.5, 0.4), progress)
               ), gid);
    
}
