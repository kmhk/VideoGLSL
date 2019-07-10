//
//  transition_colorphase.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/10/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>

using namespace metal;

kernel void transition_colorphase(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  device const float *progress [[ buffer(0) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    
    float4 fromStep = float4(0.0, 0.2, 0.4, 0.0);
    float4 toStep = float4(0.6, 0.8, 1.0, 1.0);
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    outTexture.write(mix(secOrig, orig, smoothstep(fromStep, toStep, float4(prog))), gid);
}
