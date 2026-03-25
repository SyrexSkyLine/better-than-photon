#include "/include/global.glsl"

layout(location = 0) out vec3 scene_color;

/* RENDERTARGETS: 0 */

in vec2 uv;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 cameraSpeed;

uniform float frameTime;
uniform float near;
uniform float far;

uniform vec2 view_res;
uniform vec2 view_pixel_size;
uniform vec2 taa_offset;

#define TEMPORAL_REPROJECTION
#include "/include/utility/space_conversion.glsl"

// ======================================================================
// CONFIG
// ======================================================================
#define MOTION_BLUR_SAMPLES 48 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64]

// 0 = default
// 1 = smooth / animated
// 2 = Garry's Mod style
// 3 = linear
// 4 = dynamic (only player movement)
#define MOTION_BLUR_STYLE 0 // [0 1 2 3 4]

#define MOTION_BLUR_STRENGTH 1.0 // [0.25 0.50 0.55 0.68 0.77 0.80 0.95 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]
#define MAX_BLUR_RADIUS 40.0 // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0]

// ======================================================================
// NOISE
// ======================================================================

float InterleavedGradientNoise(vec2 coord) {
    return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}

// ======================================================================
// UE VELOCITY CLAMP
// ======================================================================

vec2 UEVelocityClamp(vec2 velocityPx) {
    float len = length(velocityPx);
    float clampedLen = mix(
        len,
        MAX_BLUR_RADIUS,
        smoothstep(MAX_BLUR_RADIUS * 0.6, MAX_BLUR_RADIUS, len)
    );
    return velocityPx * (clampedLen / max(len, 1e-6));
}

// ======================================================================
// MAIN
// ======================================================================

void main() {
    ivec2 texel      = ivec2(gl_FragCoord.xy);
    ivec2 view_texel = ivec2(gl_FragCoord.xy * taau_render_scale);
    vec2 screenCoord = gl_FragCoord.xy * view_pixel_size;

    float depth = texelFetch(depthtex0, view_texel, 0).x;


    if (depth < hand_depth) {
        scene_color = texelFetch(colortex0, texel, 0).rgb;
        return;
    }

    vec3 baseColor = texelFetch(colortex0, texel, 0).rgb;

    #ifdef MOTION_BLUR

    vec2 velocity = uv - reproject(vec3(uv, depth)).xy;


    vec2 blurVelocity = velocity / view_pixel_size;


    float horizSpeed = length(cameraSpeed.xz);
    float vertSpeed  = abs(cameraSpeed.y);
    float moveSpeed  = max(horizSpeed, vertSpeed * 0.7);

    #if MOTION_BLUR_STYLE == 0
        blurVelocity *= MOTION_BLUR_STRENGTH;

    #elif MOTION_BLUR_STYLE == 1
        float smoothFactor = smoothstep(2.0, 12.0, length(blurVelocity));
        smoothFactor *= smoothFactor;
        blurVelocity *= MOTION_BLUR_STRENGTH * smoothFactor;

    #elif MOTION_BLUR_STYLE == 2
        blurVelocity = normalize(blurVelocity + 1e-6) *
                       pow(length(blurVelocity), 1.2) *
                       MOTION_BLUR_STRENGTH * 2.2;

    #elif MOTION_BLUR_STYLE == 3
        blurVelocity *= MOTION_BLUR_STRENGTH * 0.5;

    #elif MOTION_BLUR_STYLE == 4
        float moveFactor = smoothstep(0.02, 0.15, moveSpeed);
        if (moveFactor < 0.01) {
            scene_color = baseColor;
            return;
        }
        blurVelocity *= MOTION_BLUR_STRENGTH * moveFactor;
    #endif


    if (length(blurVelocity) < 1e-7) {
        scene_color = baseColor;
        return;
    }

    // UE clamp
    blurVelocity = UEVelocityClamp(blurVelocity);

    blurVelocity *= view_pixel_size;

    float dither  = InterleavedGradientNoise(gl_FragCoord.xy);
    float rSteps  = 1.0 / float(MOTION_BLUR_SAMPLES);

    blurVelocity *= rSteps;

    vec2 sampleCoord = screenCoord + blurVelocity * dither;
    sampleCoord -= blurVelocity * float(MOTION_BLUR_SAMPLES) * 0.5;

    ivec2 texSizeM1 = ivec2(view_res) - 2;

    vec3 blur = vec3(0.0);

    for (uint i = 0u; i < MOTION_BLUR_SAMPLES; ++i) {
        ivec2 tap = clamp(ivec2(sampleCoord * view_res), ivec2(2), texSizeM1);
        blur += texelFetch(colortex0, tap, 0).rgb;
        sampleCoord += blurVelocity;
    }

    scene_color = blur * rSteps;

    #else
        scene_color = baseColor;
    #endif
}