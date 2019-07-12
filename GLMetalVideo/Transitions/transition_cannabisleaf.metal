//
//  transition_cannabisleaf.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_cannabisleaf(texture2d<float, access::read> inTexture [[ texture(0) ]],
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
    
    if(prog == 0.0){
        outTexture.write(secOrig, gid);
    }
    float2 leaf_uv = (ngid - float2(0.5))/10./pow(prog,3.5);
    leaf_uv.y += 0.35;
    float r = 0.18;
    float o = atan2(leaf_uv.y, leaf_uv.x);
    outTexture.write(mix(secOrig, orig, 1.-step(1. - length(leaf_uv)+r*(1.+sin(o))*(1.+0.9 * cos(8.*o))*(1.+0.1*cos(24.*o))*(0.9+0.05*cos(200.*o)), 1.)), gid);
    
}
