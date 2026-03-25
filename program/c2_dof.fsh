#include "/include/global.glsl"

layout(location = 0) out vec3 scene_color;

/* RENDERTARGETS: 0 */

in vec2 uv;

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float near, far;
uniform float aspectRatio;
uniform float centerDepthSmooth;

uniform int frameCounter;

uniform vec2 view_pixel_size;
uniform vec2 taa_offset;

#include "/include/misc/lod_mod_support.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/sampling.glsl"
#include "/include/utility/space_conversion.glsl"

#define DOF_CHROMA_DISPERSION
#define DOF_SAMPLES 48 // [0.0 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 35.0 40.0 48.0 50.0]
#define DOF_INTENSITY 0.02 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DOF_ANAMORPHIC_RATIO 1.0 // [0.0 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0]
#define FOCUS_MODE 0
#define MANUAL_FOCUS 5.0 // [0.0 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0]
#define CAMERA_APERTURE 2.8 // [0.0 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0]
#define DOF_APERTURE_SHAPE 2 // [0 1 2]
// 0 = circle
// 1 = hexagon
// 2 = octagon
#define DOF_CAT_EYE
#define CAT_EYE_STRENGTH 0.6 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define MAX_COC_RADIUS 25.0 // [0.0 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0]
#define COC_SMOOTH_START 0.6 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// NEW ADVANCED FEATURES
#define DOF_BOKEH_HIGHLIGHTS // Підсилення яскравих областей в bokeh
#define BOKEH_HIGHLIGHT_THRESHOLD 0.8 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BOKEH_HIGHLIGHT_GAIN 2.5 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

#define DOF_BOKEH_RING // Кільцевий ефект на краях bokeh (spherical aberration)
#define BOKEH_RING_INTENSITY 0.3 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define DOF_CINEMATIC_BLUR // Кінематографічний розмитий перехід
#define CINEMATIC_BLUR_STRENGTH 1.2 // [0.5 0.8 1.0 1.2 1.5 2.0 2.5 3.0]

#define DOF_VIGNETTE_BLUR // Додатковий blur на краях екрану
#define VIGNETTE_BLUR_STRENGTH 0.4 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define DOF_ADAPTIVE_SAMPLING // Адаптивна кількість семплів залежно від CoC
#define DOF_NEAR_BLUR_BOOST 1.5 // [1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]












float GetDepthLinear(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float CalculateCoCAdvanced(float p, float z, float a, float f) {
    float coc = (1.0 - p / z) * a * f / (p - f);
    if (z < p) coc *= DOF_NEAR_BLUR_BOOST;
    return coc;
}

float ClampCoC(float coc) {
    float a = abs(coc);
    float c = mix(a, MAX_COC_RADIUS,
        smoothstep(MAX_COC_RADIUS * COC_SMOOTH_START, MAX_COC_RADIUS, a));
    return sign(coc) * c;
}

float PolygonMask(vec2 p, int sides) {
    float a = atan(p.y, p.x);
    float r = length(p);
    float k = tau / float(sides);
    float d = cos(floor(0.5 + a / k) * k - a) * r;
    return smoothstep(1.0, 0.98, d);
}

float BokehRing(vec2 offset, vec2 CoC) {
    float dist = length(offset / CoC);
    #ifdef DOF_BOKEH_RING
        return 1.0 + BOKEH_RING_INTENSITY * smoothstep(0.7, 1.0, dist);
    #else
        return 1.0;
    #endif
}

float BokehHighlightWeight(vec3 color) {
    #ifdef DOF_BOKEH_HIGHLIGHTS
        float luma = dot(color, vec3(0.299, 0.587, 0.114));
        float highlight = smoothstep(BOKEH_HIGHLIGHT_THRESHOLD, 1.0, luma);
        return 1.0 + highlight * BOKEH_HIGHLIGHT_GAIN;
    #else
        return 1.0;
    #endif
}

vec2 ApplyCatEye(vec2 offset, vec2 uv) {
    vec2 fromCenter = uv - 0.5;
    float vignette = length(fromCenter) * 2.0;
    float squeeze = mix(1.0, 1.0 - CAT_EYE_STRENGTH, vignette);
    return vec2(offset.x * squeeze, offset.y);
}

float VignetteBlur(vec2 uv) {
    #ifdef DOF_VIGNETTE_BLUR
        vec2 fromCenter = (uv - 0.5) * 2.0;
        float vignette = length(fromCenter);
        return 1.0 + VIGNETTE_BLUR_STRENGTH * vignette * vignette;
    #else
        return 1.0;
    #endif
}

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);
    ivec2 texSize = textureSize(colortex0, 0) - 1;
    vec2 screenCoord = gl_FragCoord.xy * view_pixel_size;

    float depth = texelFetch(depthtex0, texel, 0).x;

#ifdef LOD_MOD_ACTIVE
    float depth_lod = texelFetch(lod_depth_tex, texel, 0).x;
    if (is_lod_terrain(depth, depth_lod)) {
        depth = view_to_screen_space_depth(
            gbufferProjection,
            screen_to_view_space_depth(lod_projection_matrix_inverse, depth_lod)
        );
    }
#endif

    // Небо и рука — без DOF
    if (depth >= 1.0 || depth < hand_depth) {
        scene_color = texelFetch(colortex0, texel, 0).rgb;
        return;
    }

    float focusDist = GetDepthLinear(centerDepthSmooth);

    float focalLength = 0.5 * 0.035 * gbufferProjection[1][1];
    float aperture    = focalLength / CAMERA_APERTURE;
    float dist = GetDepthLinear(depth);

    float coc = CalculateCoCAdvanced(focusDist, dist, aperture, focalLength);
    coc = ClampCoC(coc);

    float vignetteModifier = VignetteBlur(screenCoord);

    vec2 CoC = vec2(coc * DOF_ANAMORPHIC_RATIO, coc * aspectRatio);
    CoC *= (1.0 / view_pixel_size) * DOF_INTENSITY * 1e3 * vignetteModifier;

    // Ограничиваем CoC в пикселях
    float cocLen = length(CoC);
    if (cocLen > MAX_COC_RADIUS) CoC *= MAX_COC_RADIUS / cocLen;

    // Если CoC совсем мал — возвращаем оригинал без блюра
    if (cocLen < 0.5) {
        scene_color = texelFetch(colortex0, texel, 0).rgb;
        return;
    }

    #ifdef DOF_ADAPTIVE_SAMPLING
        uint adaptiveSamples = uint(mix(
            float(DOF_SAMPLES) * 0.5,
            float(DOF_SAMPLES),
            smoothstep(0.0, MAX_COC_RADIUS * 0.5, cocLen)
        ));
        adaptiveSamples = max(adaptiveSamples, 8u);
    #else
        uint adaptiveSamples = uint(DOF_SAMPLES);
    #endif

    float goldenAngle = tau / (golden_ratio + 1.0);
    mat2 goldenRot = mat2(
        cos(goldenAngle), -sin(goldenAngle),
        sin(goldenAngle),  cos(goldenAngle)
    );

    float noise = texelFetch(noisetex, texel & 511, 0).b;
    noise = r1(frameCounter, noise);

    vec2 rot = vec2(cos(noise * tau), sin(noise * tau)) * CoC;

    #ifdef DOF_CHROMA_DISPERSION
        vec2 chromaDir      = normalize(screenCoord - 0.5);
        float chromaStrength = length(CoC) * 0.5;
        ivec2 chromaOffset   = ivec2(chromaDir * chromaStrength);
    #endif

    scene_color = vec3(0.0);
    float weightSum = 0.0;
    const float rSteps = 1.0 / float(DOF_SAMPLES);

    for (uint i = 0u; i < adaptiveSamples; ++i, rot *= goldenRot) {
        float r = sqrt((noise + float(i)) * rSteps);
        vec2 offset = rot * r;

        #ifdef DOF_CAT_EYE
            offset = ApplyCatEye(offset, screenCoord);
        #endif

        float shapeMask = 1.0;
        #if DOF_APERTURE_SHAPE == 1
            shapeMask = PolygonMask(offset / CoC, 6);
        #elif DOF_APERTURE_SHAPE == 2
            shapeMask = PolygonMask(offset / CoC, 8);
        #endif

        float ringEffect = BokehRing(offset, CoC);

        #ifdef DOF_CHROMA_DISPERSION
            ivec2 sc  = clamp(texel + ivec2(offset),               ivec2(0), texSize);
            ivec2 sc2 = clamp(texel + ivec2(offset) + chromaOffset, ivec2(0), texSize);
            ivec2 sc3 = clamp(texel + ivec2(offset) - chromaOffset, ivec2(0), texSize);
            vec3 sampleColor;
            sampleColor.r = texelFetch(colortex0, sc2, 0).r;
            sampleColor.g = texelFetch(colortex0, sc,  0).g;
            sampleColor.b = texelFetch(colortex0, sc3, 0).b;
        #else
            ivec2 sc = clamp(texel + ivec2(offset), ivec2(0), texSize);
            vec3 sampleColor = texelFetch(colortex0, sc, 0).rgb;
        #endif

        float highlightWeight = BokehHighlightWeight(sampleColor);
        float w = shapeMask * ringEffect * highlightWeight;

        weightSum   += w;
        scene_color += sampleColor * w;
    }

    scene_color /= max(weightSum, 1e-4);
}

#ifndef DOF
#error "This program should be disabled if Depth of Field is disabled"
#endif