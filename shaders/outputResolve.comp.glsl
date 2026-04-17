#version 460

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_buffer_reference : require

layout ( local_size_x = 16, local_size_y = 16 ) in;

layout ( rgba32f, set = 0, binding = 1 ) uniform image2D lenticularLUT;
layout ( rgba32f, set = 0, binding = 2 ) uniform image2D accumulator;

#include "common.h"

const float maxDist = 1e10f;
const vec2 distBound = vec2( 0.0001f, maxDist );

float RayBoxIntersect ( in vec3 ro, in vec3 rd, in vec3 boxSize, in vec3 boxPosition ) {
	ro -= boxPosition;

	vec3 m = sign( rd ) / max( abs( rd ), 1e-8 );
	vec3 n = m * ro;
	vec3 k = abs( m ) * boxSize;

	vec3 t1 = -n - k;
	vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );

	if ( tN > tF || tF <= 0.0f ) {
		return maxDist;
	} else {
		if ( tN >= distBound.x && tN <= distBound.y ) {
			return tN;
		} else if ( tF >= distBound.x && tF <= distBound.y ) {
			return tF;
		} else {
			return maxDist;
		}
	}
}

void main () {
	ivec2 idx = ivec2( gl_GlobalInvocationID.xy );

	vec2 uv = 2.0f * ( idx + vec2( 0.5f ) ) / vec2( imageSize( accumulator ).xy ) - vec2( 1.0f );
	uv.x *= float( imageSize( accumulator ).x ) / float( imageSize( accumulator ).y );

	// create a view ray
	 vec3 rayOrigin = GlobalData.zoomFactor * ( uv.x * GlobalData.viewBasisX + uv.y * GlobalData.viewBasisY ) - 10.0f * GlobalData.viewBasisZ;

	// primary ray intersects with the bounds...
	float dBounds = RayBoxIntersect( rayOrigin, GlobalData.viewBasisZ, vec3( 1.0f ), vec3( 0.0f ) );

	vec3 color = ( dBounds == maxDist ) ? ( vec3( 1.0f, 0.0f, 0.0f ) ) : ( vec3( 1.0f / dBounds ) );
	// vec3 color = vec3( uv, 0.0f );
//	vec3 color = rayOrigin;

	// if the ray hits, we're pathtracing

	// else, we're taking a black sample

	// writing a result back to the accumulator...
		// handling image reset, here - cancel history and only write this frame's data

	imageStore( accumulator, idx, vec4( color, 1.0f ) );
}