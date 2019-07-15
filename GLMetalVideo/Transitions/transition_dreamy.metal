//
//  transition_dreamy.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

float2 offset(float progress, float x, float theta) {
    float phase = progress*progress + progress + theta;
    float shifty = 0.03*progress*cos(10.0*(progress+x));
    return float2(0, shifty);
}

kernel void transition_dreamy(texture2d<float, access::read> inTexture [[ texture(0) ]],
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
    
    outTexture.write(mix(
                         inTexture2.read(toUint2(ngid + offset(prog, ngid.x, 0.0), inTexture2)),
                         inTexture.read(toUint2(ngid + offset(1.0-prog, ngid.x, 3.14), inTexture)),
                         prog), gid);
}
