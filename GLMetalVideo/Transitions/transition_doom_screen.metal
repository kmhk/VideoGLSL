//
//  transition_doom_screen.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/14/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
#include <metal_common>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);


float rand(int num) {
    return fract(fmod(float(num) * 67123.313, 12.0) * sin(float(num) * 10.3) * cos(float(num)));
}

float wave(int num, float frequency, int bars) {
    float fn = float(num) * frequency * 0.1 * float(bars);
    return cos(fn * 0.5) * cos(fn * 0.13) * sin((fn+10.0) * 0.3) / 2.0 + 0.5;
}

float drip(int num, float dripScale, int bars) {
    return sin(float(num) / float(bars - 1) * 3.141592) * dripScale;
}

float pos(int num, int bars, float noise, float frequency, float dripScale) {
    return (noise == 0.0 ? wave(num, frequency, bars) : mix(wave(num, frequency, bars), rand(num), noise)) + (dripScale == 0.0 ? 0.0 : drip(num, dripScale, bars));
}

kernel void transition_doom_screen(texture2d<float, access::read> inTexture [[ texture(0) ]],
                            texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                            texture2d<float, access::write> outTexture [[ texture(2) ]],
                            device const float *progress [[ buffer(0) ]],
                            device const int *bars_ [[ buffer(1) ]],
                            device const float *ampl [[ buffer(2) ]],
                            device const float *noise_ [[ buffer(3) ]],
                            device const float *freq [[ buffer(4) ]],
                            device const float *drip [[ buffer(5) ]],
                            uint2 gid [[ thread_position_in_grid ]])
{
    int bars = *bars_;
    float amplitude = *ampl;
    float noise = *noise_;
    float frequency = *freq;
    float dripScale = *drip;
    
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    //ngid.y = 1- ngid.y;
    
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    
    int bar = int(ngid.x * (float(bars)));
    float scale = 1.0 + pos(bar, bars, noise, frequency, dripScale) * amplitude;
    float phase = prog * scale;
    float posY = ngid.y / float2(1.0).y;
    float2 p;
    float4 c;
    if (phase + posY < 1.0) {
        p = float2(ngid.x, ngid.y + mix(0.0, float2(1.0).y, phase)) / float2(1.0).xy;
        c = inTexture2.read(toUint2(p, inTexture2));
    } else {
        p = ngid.xy / float2(1.0).xy;
        c = inTexture.read(toUint2(p, inTexture));
    }
    
    // Finally, apply the color
    outTexture.write(c, gid);
    
}
