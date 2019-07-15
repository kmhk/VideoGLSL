//
//  transition_fade_color.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_fade_color(texture2d<float, access::read> inTexture [[ texture(0) ]],
                            texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                            texture2d<float, access::write> outTexture [[ texture(2) ]],
                            device const float *progress [[ buffer(0) ]],
                            device const float *cr [[ buffer(1) ]],
                            device const float *cg [[ buffer(2) ]],
                            device const float *cb [[ buffer(3) ]],
                            device const float *cp [[ buffer(4) ]],
                            uint2 gid [[ thread_position_in_grid ]])
{
    float3 color = float3(*cr, *cg, *cb);
    float colorPhase = *cp;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    outTexture.write(mix(
               mix(float4(color, 1.0), secOrig, smoothstep(1.0-colorPhase, 0.0, prog)),
               mix(float4(color, 1.0), orig, smoothstep(    colorPhase, 1.0, prog)),
               prog), gid);
}
