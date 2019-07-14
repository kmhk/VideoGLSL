//
//  transition_cross_hatch.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

float rand(float2 co);

kernel void transition_cross_hatch(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                            texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                            texture2d<float, access::write> outTexture [[ texture(2) ]],
                                            device const float *progress [[ buffer(0) ]],
                                            device const float *cx [[ buffer(1) ]],
                                            device const float *cy [[ buffer(2) ]],
                                            device const float *thres [[ buffer(3) ]],
                                            device const float *fade [[ buffer(4) ]],
                                            uint2 gid [[ thread_position_in_grid ]])
{
    float2 center = float2(*cx, *cy);
    float threshold = *thres;
    float fadeEdge = *fade;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float dist = distance(center, ngid) / threshold;
    float r = prog - min(rand(float2(ngid.y, 0.0)), rand(float2(0.0, ngid.x)));
    outTexture.write(mix(secOrig, orig, mix(0.0, mix(step(dist, r), 1.0, smoothstep(1.0-fadeEdge, 1.0, prog)), smoothstep(0.0, fadeEdge, prog))), gid);
    
}
