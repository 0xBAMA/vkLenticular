#version 460

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_buffer_reference : require

layout ( local_size_x = 16, local_size_y = 16 ) in;

layout ( rgba32f, set = 0, binding = 1 ) uniform image2D lenticularLUT;

#include "common.h"

void main () {
	ivec2 idx = ivec2( gl_GlobalInvocationID.xy );

	// we need to figure out what pixel this invocation corresponds to

	// we need to figure out what angle this invocation corresponds to

	// we need to shoot a ray into the scene geometry, from that starting point, along that direction

	// we need to store back the result, into the lenticular LUT

}