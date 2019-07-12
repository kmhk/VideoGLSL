//
//  transition_bow_tie_vertical.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//


#include <metal_stdlib>
#include <metal_math>
#include <metal_geometric>

using namespace metal;

// Definded in horizontal
float check(float2 p1, float2 p2, float2 p3);
bool PointInTriangle (float2 pt, float2 p1, float2 p2, float2 p3);
float blur_edge(float2 bot1, float2 bot2, float2 top, float2 testPt);


bool in_top_triangle(float2 p, float progress, float2 top_left, float2 top_right, float2 center){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(center.x, (top_left.y + top_right.x) / 2 + progress);
    vertex2 = float2(center.x-progress, top_left.y);
    vertex3 = float2(center.x+progress, top_right.y);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

bool in_bottom_triangle(float2 p, float progress, float2 bottom_left, float2 bottom_right, float2 center){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(center.x, (bottom_left.y + bottom_right.x) / 2 + progress);
    vertex2 = float2(center.x-progress, bottom_left.y);
    vertex3 = float2(center.x+progress, bottom_right.y);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

kernel void transition_bow_tie_vertical(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                          texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                          texture2d<float, access::write> outTexture [[ texture(2) ]],
                                          device const float *progress [[ buffer(0) ]],
                                          device const float *blx [[ buffer(1) ]],
                                          device const float *bly [[ buffer(2) ]],
                                          device const float *brx [[ buffer(3) ]],
                                          device const float *bry [[ buffer(4) ]],
                                          device const float *tlx [[ buffer(5) ]],
                                          device const float *tly [[ buffer(6) ]],
                                          device const float *trx [[ buffer(7) ]],
                                          device const float *try_ [[ buffer(8) ]],
                                          device const float *cx [[ buffer(9) ]],
                                          device const float *cy [[ buffer(10) ]],
                                          uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 bottom_left = float2(*blx, *bly);
    float2 bottom_right = float2(*brx, *bry);
    float2 top_left = float2(*tlx, *tly);
    float2 top_right = float2(*trx, *try_);
    float2 center = float2(*cx, *cy);
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    
    if (in_top_triangle(ngid, prog, top_left, top_right, center))
    {
        if (prog < 0.1)
        {
            outTexture.write(secOrig, gid);
        }
        if (ngid.y < 0.5)
        {
            float2 vertex1, vertex2, vertex3;
            vertex1 = float2(center.x, (top_left.y + top_right.x) / 2 + prog);
            vertex2 = float2(center.x-prog, top_left.y);
            vertex3 = float2(center.x+prog, top_right.y);
            outTexture.write(mix(
                                 secOrig,
                                 orig,
                                 blur_edge(vertex2, vertex3, vertex1, ngid)
                                 ), gid);
        }
        else
        {
            if (prog > 0.0)
            {
                outTexture.write(orig, gid);
            }
            else
            {
                outTexture.write(secOrig, gid);
            }
        }
    }
    else if (in_bottom_triangle(ngid, prog, bottom_left, bottom_right, center))
    {
        if (ngid.y >= 0.5)
        {
            float2 vertex1, vertex2, vertex3;
            vertex1 = float2(center.x, (bottom_left.y + bottom_right.x) / 2 + prog);
            vertex2 = float2(center.x-prog, bottom_left.y);
            vertex3 = float2(center.x+prog, bottom_right.y);
            outTexture.write(mix(
                                 secOrig,
                                 orig,
                                 blur_edge(vertex2, vertex3, vertex1, ngid)
                                 ), gid);
        }
        else
        {
            outTexture.write(secOrig, gid);
        }
    }
    else {
        outTexture.write(secOrig, gid);
    }
    
}
