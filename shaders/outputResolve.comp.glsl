#version 460

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_buffer_reference : require

layout ( local_size_x = 16, local_size_y = 16 ) in;

layout ( rgba32f, set = 0, binding = 1 ) uniform image2D lenticularLUT;
layout ( rgba32f, set = 0, binding = 2 ) uniform image2D accumulator;

#include "common.h"

void main () {
	ivec2 idx = ivec2( gl_GlobalInvocationID.xy );

	// create a view ray

	// primary ray intersects with the bounds...

	vec3 color = vec3( 1.0f );
	// if the ray hits, we're pathtracing

	// else, we're taking a black sample

	// writing a result back to the accumulator...
		// handling image reset, here - cancel history and only write this frame's data

	imageStore( accumulator, idx, vec4( color, 1.0f ) );
}