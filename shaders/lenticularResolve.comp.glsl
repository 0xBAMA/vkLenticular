#version 460

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_buffer_reference : require

layout ( local_size_x = 16, local_size_y = 16 ) in;

layout ( rgba8, set = 0, binding = 1 ) uniform image2D lenticularLUT;

#include "common.h"

vec2 RaySphereIntersect ( vec3 r0, vec3 rd, vec3 s0, float sr ) {
	// r0 is ray origin
	// rd is ray direction
	// s0 is sphere center
	// sr is sphere radius
	// return is the roots of the quadratic, includes negative hits
	float a = dot( rd, rd );
	vec3 s0_r0 = r0 - s0;
	float b = 2.0f * dot( rd, s0_r0 );
	float c = dot( s0_r0, s0_r0 ) - ( sr * sr );
	float disc = b * b - 4.0f * a * c;
	if ( disc < 0.0f ) {
		return vec2( -1.0f, -1.0f );
	} else {
		return vec2( -b - sqrt( disc ), -b + sqrt( disc ) ) / ( 2.0f * a );
	}
}

void main () {
	ivec2 idx = ivec2( gl_GlobalInvocationID.xy );

	// we need to figure out what pixel this invocation corresponds to -> informs ray origin
	ivec2 pixelIdx = idx / GlobalData.gridDivisions;
	vec3 rayOrigin = vec3(
		remap( float( pixelIdx.x + 0.5f ), 0.0f, GlobalData.gridBaseDim, -1.0f, 1.0f ),
		remap( float( pixelIdx.y + 0.5f ), 0.0f, GlobalData.gridBaseDim, -1.0f, 1.0f ),
		0.0f
	);

	// we need to figure out what angle this invocation corresponds to -> informs ray direction
	ivec2 subpixelIdx = idx % GlobalData.gridDivisions;
	vec2 startAngle = vec2( // this is used to construct the vector, via rotations from a vector pointing downwards...
		remap( float( subpixelIdx.x ), 0.0f, GlobalData.gridDivisions, piHalf * GlobalData.angleScale, -piHalf * GlobalData.angleScale ),
		remap( float( subpixelIdx.y ), 0.0f, GlobalData.gridDivisions, piHalf * GlobalData.angleScale, -piHalf * GlobalData.angleScale )
	);
	vec3 rayDirection = Rotate3D( startAngle.x, vec3( 0.0f, 1.0f, 0.0f ) ) * Rotate3D( startAngle.y, vec3( 1.0f, 0.0f, 0.0f ) ) * vec3( 0.0f, 0.0f, -1.0f );

	vec3 sphereCenter = vec3( 0.0f, 0.0f, -1.5f );
	vec2 roots = RaySphereIntersect( rayOrigin, rayDirection, sphereCenter, 1.0f );
	vec3 color = vec3( 1.0f );
	if ( roots != vec2( -1.0f ) ) {
		vec3 p = rayOrigin + rayDirection * roots.x;
		color = normalize( p - sphereCenter ) * step( mod( p.z, 0.2f ), 0.1f );
	}

	// we need to store back the result, into the lenticular LUT
	imageStore( lenticularLUT, idx, vec4( color, 1.0f ) );
}