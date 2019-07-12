//
//  transition_butterfly_wave_scrawler.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>

using namespace metal;

#define PI 3.141592653589

float butterfly_compute(float2 p, float progress, float2 center, float amplitude, float waves) {
    float2 o = p*sin(progress * amplitude)-center;
    // horizontal vector
    float2 h = float2(1., 0.);
    // butterfly polar function (don't ask me why this one :))
    float theta = acos(dot(o, h)) * waves;
    return (exp(cos(theta)) - 2.*cos(4.*theta) + pow(sin((2.*theta - PI) / 24.), 5.)) / 10.;
}

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture) {
    return uint2(ngid.x * inTexture.get_width(), ngid.y * inTexture.get_height());
}

kernel void transition_butterfly_wave_scrawler(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                    texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    texture2d<float, access::read> samplerTex [[ texture(3) ]],
                                    device const float *progress [[ buffer(0) ]],
                                    device const float *ampl [[ buffer(1) ]],
                                    device const float *wave [[ buffer(2) ]],
                                    device const float *separation [[ buffer(3) ]],
                                    uint2 gid [[ thread_position_in_grid ]])
{
    
    float amplitude = *ampl; // = 1.0
    float waves = *wave; // = 30.0
    float colorSeparation = *separation; // = 0.3

    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 p = ngid.xy / float2(1.0).xy;
    float inv = 1. - prog;
    float2 dir = p - float2(.5);
    float dist = length(dir);
    float disp = butterfly_compute(p, prog, float2(0.5, 0.5), amplitude, waves) ;
    float4 texTo = inTexture.read(toUint2(p + inv*disp, inTexture));
    float4 texFrom = float4(
                        inTexture2.read(toUint2(p + prog*disp*(1.0 - colorSeparation), inTexture2)).r,
                        inTexture2.read(toUint2(p + prog*disp, inTexture2)).g,
                        inTexture2.read(toUint2(p + prog*disp*(1.0 + colorSeparation), inTexture2)).b,
                        1.0);
    outTexture.write(texTo*prog + texFrom*inv, gid);
}

