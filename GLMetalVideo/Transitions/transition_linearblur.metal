//
//  transition_linearblur.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/11/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


#include <metal_stdlib>
#include <metal_common>
#include <metal_geometric>

using namespace metal;

kernel void transition_linearblur(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  device const float *progress [[ buffer(0) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    float intensity = 0.1;
    int passes = 6;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    float limit = 0.5;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float4 c1 = float4(0.0);
    float4 c2 = float4(0.0);
    
    float disp = intensity*(0.5-/*distance*/(0.5 - prog));
    for (int xi=0; xi<passes; xi++)
    {
        float x = float(xi) / float(passes) - 0.5;
        for (int yi=0; yi<passes; yi++)
        {
            float y = float(yi) / float(passes) - 0.5;
            float2 v = float2(x,y);
            float d = disp;
            
            float2 new_uv = ngid + d * v;
            new_uv.x *= inTexture.get_width();
            new_uv.y *= inTexture.get_height();
            
            uint2 new_gid = uint2(new_uv);
            c1 += inTexture2.read( new_gid);
            c2 += inTexture.read( new_gid);
        }
    }
    c1 /= float(passes*passes);
    c2 /= float(passes*passes);
    
    outTexture.write(mix(c1, c2, prog), gid);
}
