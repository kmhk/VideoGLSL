//
//  transition_bow_tie_horizontal.metal
//  VideoTrasition
//
//  Created by MacMaster on 7/12/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
#include <metal_geometric>

using namespace metal;

float check(float2 p1, float2 p2, float2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool PointInTriangle (float2 pt, float2 p1, float2 p2, float2 p3)
{
    bool b1, b2, b3;
    b1 = check(pt, p1, p2) < 0.0;
    b2 = check(pt, p2, p3) < 0.0;
    b3 = check(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}

bool in_left_triangle(float2 p, float progress, float2 top_left, float2 bottom_left, float2 center){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2((top_left.x + bottom_left.x) / 2 + progress, center.y);
    vertex2 = float2(top_left.x, center.y-progress);
    vertex3 = float2(bottom_left.x, center.y+progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

bool in_right_triangle(float2 p, float progress, float2 top_right, float2 bottom_right, float2 center){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2((top_right.x + bottom_right.x) / 2 -progress, center.y);
    vertex2 = float2(top_right.x, center.y-progress);
    vertex3 = float2(bottom_right.x, center.y+progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

float blur_edge(float2 bot1, float2 bot2, float2 top, float2 testPt)
{
    float2 lineDir = bot1 - top;
    float2 perpDir = float2(lineDir.y, -lineDir.x);
    float2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));
    
    lineDir = bot2 - top;
    perpDir = float2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);
    
    if (min_dist < 0.005) {
        return min_dist / 0.005;
    }
    else  {
        return 1.0;
    };
}

kernel void transition_bow_tie_horizontal(texture2d<float, access::read> inTexture [[ texture(0) ]],
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
    
    
    if (in_left_triangle(ngid, prog, top_left, bottom_left, center))
    {
        if (prog < 0.1)
        {
            outTexture.write(secOrig, gid);
        }
        if (ngid.x < 0.5)
        {
            float2 vertex1 = float2((top_left.x + bottom_left.x) / 2 + prog, center.y);
            float2 vertex2 = float2(top_left.x, center.y-prog);
            float2 vertex3 = float2(bottom_left.x, center.y+prog);
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
    else if (in_right_triangle(ngid, prog, top_right, bottom_right, center))
    {
        if (ngid.x >= 0.5)
        {
            float2 vertex1 = float2((top_right.x + bottom_right.x) / 2 -prog, center.y);
            float2 vertex2 = float2(top_right.x, center.y-prog);
            float2 vertex3 = float2(bottom_right.x, center.y+prog);
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


