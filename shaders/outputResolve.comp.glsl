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

vec3 boxNormal ( vec3 p ) {
	// sort of an approximation... take the normal of the nearest face
	const float ome = 1.0f - 0.00001f; // one minus epsilon
	if ( abs( p.x ) > ome ) {
		return vec3( 1.0f, 0.0f, 0.0f ) * sign( p.x );
	} else if ( abs( p.y ) > ome ) {
		return vec3( 0.0f, 1.0f, 0.0f ) * sign( p.y );
	} else if ( abs( p.z ) > ome ) {
		return vec3( 0.0f, 0.0f, 1.0f ) * sign( p.z );
	} else {
		// shouldn't hit this
		return vec3( 1.0f );
	}
}

float rayPlaneIntersect ( in vec3 rayOrigin, in vec3 rayDirection ) {
	const vec3 normal = vec3( 0.0f, 1.0f, 0.0f );
	const vec3 planePt = vec3( 0.0f, 0.0f, 0.0f ); // not sure how far down this should be
	return -( dot( rayOrigin - planePt, normal ) ) / dot( rayDirection, normal );
}

void main () {
	ivec2 idx = ivec2(gl_GlobalInvocationID.xy);

	vec2 uv = (2.0f * (vec2(idx) + vec2(0.5f)) / vec2(imageSize(accumulator).xy)) - vec2(1.0f);
	uv.x *= float(imageSize(accumulator).x) / float(imageSize(accumulator).y);

	// create a view ray
	vec3 rayOrigin = GlobalData.zoomFactor * (uv.x * GlobalData.viewBasisX + uv.y * GlobalData.viewBasisY) - 10.0f * GlobalData.viewBasisZ;
	vec3 rayDirection = GlobalData.viewBasisZ;

	vec4 color = vec4( 0.0f );
	if ( Intersect( rayOrigin, rayDirection ) ) {
		// if the ray hits, we're pathtracing

		vec3 pInitial = rayOrigin + rayDirection * tMin;
		rayOrigin = pInitial + rayDirection * 0.0001f;

		vec3 normal = boxNormal( pInitial );
		rayDirection = refract( rayDirection, normal, 1.0f / 1.5f );

		float dPlane = rayPlaneIntersect( rayOrigin, rayDirection );
		vec3 pHit = rayOrigin + rayDirection * dPlane;
		if ( dPlane > 0.0f && pHit.x < 0.5f && pHit.x >= -0.5f && pHit.z < 0.5f && pHit.z >= -0.5f ) {
			color.xyz = vec3( pHit );
		}

//		float transmission = 1.0f;
//		for ( int i = 0; i < 4; i++ ) {

			// scene intersection - in the box, rays can't escape...
				// Hit one of three things first:
					// the mirror box
					// the lenticular panel (light side)
					// the lenticular panel (dark side)

			// if you hit the panel - you have a color, or you hit the dark side

				// if you hit the dark side, the ray dies, we take color as 0

				// else get the value out of the lenticular LUT
					// pixel select
						// plane X, Y -> spatial mapping
					// subpixel select
						// plane X, Y, ray direction -> directional mapping

				// color is transmission * sampled color

			// else need to keep bouncing

				// attenuate transmission by wall albedo

				// get the normal at the hit point - this happens *at* the hit point, before epsilon bump is considered

				// epsilon bump + rayOrigin update

//		}
	}

	imageStore( accumulator, idx, color );
}