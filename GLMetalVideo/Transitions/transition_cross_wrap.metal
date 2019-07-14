//
//  transition_cross_wrap.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

kernel void transition_cross_wrap(texture2d<float, access::read> inTexture [[ texture(0) ]],
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
    
    float x = prog;
    x=smoothstep(.0,1.0,(x*2.0+ngid.x-1.0));
    outTexture.write(mix(inTexture2.read(toUint2((ngid-.5)*(1.-x)+.5, inTexture2)), inTexture.read(toUint2((ngid-.5)*x+.5, inTexture)), x), gid);
    
}

