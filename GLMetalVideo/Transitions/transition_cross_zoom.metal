//
//  transition_cross_zoom.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/13/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
#include <metal_common>

using namespace metal;

uint2 toUint2(float2 ngid, texture2d<float, access::read> inTexture);

float rand (float2 co);

float Linear_ease(float begin, float change, float duration, float time) {
    return change * time / duration + begin;
}

float Exponential_easeInOut(float begin, float change, float duration, float time) {
    if (time == 0.0)
        return begin;
    else if (time == duration)
        return begin + change;
    time = time / (duration / 2.0);
    if (time < 1.0)
        return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
    return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
    const float PI = 3.141592653589793;
    return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
}

float3 crossFade(float2 uv, float dissolve, float4 from, float4 to) {
    return mix(from.rgb, to.rgb, dissolve);
}

kernel void transition_cross_zoom(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                    texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    device const float *progress [[ buffer(0) ]],
                                    device const float *streng [[ buffer(1) ]],
                                    uint2 gid [[ thread_position_in_grid ]])
{
    float strength = *streng; // 0.4;
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    
    float2 texCoord = ngid.xy / float2(1.0).xy;
    
    // Linear interpolate center across center half of the image
    float2 center = float2(Linear_ease(0.25, 0.5, 1.0, prog), 0.5);
    float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, prog);
    
    // Mirrored sinusoidal loop. 0->strength then strength->0
    float strength1 = Sinusoidal_easeInOut(0.0, strength, 0.5, prog);
    
    float3 color = float3(0.0);
    float total = 0.0;
    float2 toCenter = center - texCoord;
    
    /* randomize the lookup values to hide the fixed number of samples */
    float offset = rand(ngid);
    
    for (float t = 0.0; t <= 40.0; t++) {
        float percent = (t + offset) / 40.0;
        float weight = 4.0 * (percent - percent * percent);
        color += crossFade(texCoord + toCenter * percent * strength1, dissolve,
                           inTexture2.read(toUint2(texCoord + toCenter * percent * strength1, inTexture2)),
                           inTexture.read(toUint2(texCoord + toCenter * percent * strength1, inTexture))) * weight;
        total += weight;
    }
    outTexture.write(float4(color / total, 1.0), gid);
}
