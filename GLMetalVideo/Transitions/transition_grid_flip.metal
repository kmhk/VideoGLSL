//
//  transition_grid_flip.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/15/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

#define PI 3.141592653589

float rand (float2 co);

float getDelta(float2 p, uint2 size) {
    float2 rectanglePos = floor(float2(size) * p);
    float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
    float top = rectangleSize.y * (rectanglePos.y + 1.0);
    float bottom = rectangleSize.y * rectanglePos.y;
    float left = rectangleSize.x * rectanglePos.x;
    float right = rectangleSize.x * (rectanglePos.x + 1.0);
    float minX = min(abs(p.x - left), abs(p.x - right));
    float minY = min(abs(p.y - top), abs(p.y - bottom));
    return min(minX, minY);
}

float getDividerSize(uint2 size, float dividerWidth) {
    float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
    return min(rectangleSize.x, rectangleSize.y) * dividerWidth;
}

kernel void transition_grid_flip(texture2d<float, access::read> inTexture [[ texture(0) ]],
                               texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                               texture2d<float, access::write> outTexture [[ texture(2) ]],
                               device const float *prog [[ buffer(0) ]],
                               device const int *sw [[ buffer(1) ]],
                               device const int *sh [[ buffer(2) ]],
                               device const float *pause_ [[ buffer(3) ]],
                               device const float *divider [[ buffer(4) ]],
                               device const float *sa [[ buffer(5) ]],
                               device const float *sg [[ buffer(6) ]],
                               device const float *sb [[ buffer(7) ]],
                               device const float *sal [[ buffer(8) ]],
                               device const float *random_ [[ buffer(9) ]],
                               uint2 gid [[ thread_position_in_grid ]])
{
    uint2 size = uint2(*sw, *sh); // = ifloat2(4)
    float pause = *pause_; // = 0.1
    float dividerWidth = *divider; // = 0.05
    float4 bgcolor = float4(*sa, *sg, *sb, *sal); // = float4(0.0, 0.0, 0.0, 1.0)
    float randomness = *random_; // = 0.1

    
    float2 p = float2(gid);
    float progress = *prog;
    p.x /= inTexture.get_width();
    p.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    if(progress < pause) {
        float currentProg = progress / pause;
        float a = 1.0;
        if(getDelta(p, size) < getDividerSize(size, dividerWidth)) {
            a = 1.0 - currentProg;
        }
        outTexture.write(mix(bgcolor, secOrig, a), gid);
    }
    else if(progress < 1.0 - pause){
        if(getDelta(p, size) < getDividerSize(size, dividerWidth)) {
            outTexture.write(bgcolor, gid);
        } else {
            float currentProg = (progress - pause) / (1.0 - pause * 2.0);
            float2 q = p;
            float2 rectanglePos = floor(float2(size) * q);
            
            float r = rand(rectanglePos) - randomness;
            float cp = smoothstep(0.0, 1.0 - r, currentProg);
            
            float rectangleSize = 1.0 / float2(size).x;
            float delta = rectanglePos.x * rectangleSize;
            float offset = rectangleSize / 2.0 + delta;
            
            p.x = (p.x - offset)/abs(cp - 0.5)*0.5 + offset;
            float4 a = secOrig;
            float4 b = orig;
            
            float s = step(abs(float2(size).x * (q.x - delta) - 0.5), abs(cp - 0.5));
            outTexture.write(mix(bgcolor, mix(b, a, step(cp, 0.5)), s), gid);
        }
    }
    else {
        float currentProg = (progress - 1.0 + pause) / pause;
        float a = 1.0;
        if(getDelta(p,size) < getDividerSize(size, dividerWidth)) {
            a = currentProg;
        }
        outTexture.write(mix(bgcolor, orig, a), gid);
    }
    
}


