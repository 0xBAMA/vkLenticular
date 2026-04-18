#version 460

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_buffer_reference : require

layout ( local_size_x = 16, local_size_y = 16 ) in;

#include "common.h"

layout ( rgba32f, set = 0, binding = 1 ) uniform image2D lenticularLUT;
layout ( rgba32f, set = 0, binding = 2 ) uniform image2D accumulator;

float tMin, tMax; // global state tracking
bool Intersect ( const vec3 rO, vec3 rD ) {
	// Intersect() code adapted from:
	//    Amy Williams, Steve Barrus, R. Keith Morley, and Peter Shirley
	//    "An Efficient and Robust Ray-Box Intersection Algorithm"
	//    Journal of graphics tools, 10(1):49-54, 2005
	const float minDistance = -100.0;
	const float maxDistance =  100.0;
	int s[ 3 ]; // sign toggle
	// inverse of ray direction
	const vec3 iD = vec3( 1.0 ) / rD;
	s[ 0 ] = ( iD[ 0 ] < 0 ) ? 1 : 0;
	s[ 1 ] = ( iD[ 1 ] < 0 ) ? 1 : 0;
	s[ 2 ] = ( iD[ 2 ] < 0 ) ? 1 : 0;
	const vec3 min = vec3( -1.0, -1.0, -1.0 );
	const vec3 max = vec3(  1.0,  1.0,  1.0 );
	const vec3 b[ 2 ] = { min, max }; // bounds
	tMin = ( b[ s[ 0 ] ][ 0 ] - rO[ 0 ] ) * iD[ 0 ];
	tMax = ( b[ 1 - s[ 0 ] ][ 0 ] - rO[ 0 ] ) * iD[ 0 ];
	const float tYMin = ( b[ s[ 1 ] ][ 1 ] - rO[ 1 ] ) * iD[ 1 ];
	const float tYMax = ( b[ 1 - s[ 1 ] ][ 1 ] - rO[ 1 ] ) * iD[ 1 ];
	if ( ( tMin > tYMax ) || ( tYMin > tMax ) ) return false;
	if ( tYMin > tMin ) tMin = tYMin;
	if ( tYMax < tMax ) tMax = tYMax;
	const float tZMin = ( b[ s[ 2 ] ][ 2 ] - rO[ 2 ] ) * iD[ 2 ];
	const float tZMax = ( b[ 1 - s[ 2 ] ][ 2 ] - rO[ 2 ] ) * iD[ 2 ];
	if ( ( tMin > tZMax ) || ( tZMin > tMax ) ) return false;
	if ( tZMin > tMin ) tMin = tZMin;
	if ( tZMax < tMax ) tMax = tZMax;
	return ( ( tMin < maxDistance ) && ( tMax > minDistance ) );
}

void main () {
	ivec2 idx = ivec2(gl_GlobalInvocationID.xy);

	vec2 uv = (2.0f * (vec2(idx) + vec2(0.5f)) / vec2(imageSize(accumulator).xy)) - vec2(1.0f);
	uv.x *= float(imageSize(accumulator).x) / float(imageSize(accumulator).y);

	// create a view ray
	vec3 rayOrigin = GlobalData.zoomFactor * (uv.x * GlobalData.viewBasisX + uv.y * GlobalData.viewBasisY) - 10.0f * GlobalData.viewBasisZ;
	vec3 rayDirection = GlobalData.viewBasisZ;

	vec4 color = vec4( 0.0f );
//	if ( GlobalData.reset != 0 ) {
//		 handling image reset, here - cancel history and only write this frame's data
//		color = vec4( 0.0f, 0.0f, 0.0f, 1.0f );
//	} else
	if ( Intersect( rayOrigin, rayDirection ) ) {
		// if the ray hits, we're pathtracing
		color.xyz = vec3( 1.0f / tMin );



//		vec4 prevColor = imageLoad( accumulator, idx );
//		float sampleCount = max( prevColor.a, 0.0f ) + 1.0f;
//		const float mixFactor = saturate( 1.0f / sampleCount );
//		color = vec4( mix( prevColor.rgb, color.rgb, mixFactor ), sampleCount );
//	} else {
//		color = vec4( 0.0f, 0.0f, 0.0f, 1.0f );
	}

	imageStore( accumulator, idx, color );
}