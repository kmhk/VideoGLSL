//
//  transition_windowblinds.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/10/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


#include <metal_stdlib>
#include <metal_common>

using namespace metal;

kernel void transition_windowblinds(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                    texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    device const float *progress [[ buffer(0) ]],
                                    uint2 gid [[ thread_position_in_grid ]])
{
    float2 ngid = float2(gid);
    float prog = *progress;
    float t = prog;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    if (fmod(floor(ngid.y*100.*prog), 2.)==0.)
        t*=2.-.5;
    
    outTexture.write(mix(
                         secOrig,
                         orig,
                         mix(t, prog, smoothstep(0.8, 1.0, prog))
                         ), gid);
}
