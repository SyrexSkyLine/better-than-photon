//ITS NOT SHITCODED I FUCK GLSL BRO

#include "/include/global.glsl"

layout(location = 0) out vec3 fragment_color;

in vec2 uv;

uniform sampler2D colortex0; // Scene color
uniform sampler2D depthtex0; // Depth

#if DEBUG_VIEW == DEBUG_VIEW_SAMPLER
uniform sampler2D DEBUG_SAMPLER;
#endif

uniform float viewHeight;
uniform float viewWidth;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform vec2 view_res;

// Bodycam uniforms
uniform float isSneaking;
uniform vec3 cameraSpeed;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

#ifdef COLORED_LIGHTS
uniform sampler2D shadowtex0;
#endif

#include "/include/utility/bicubic.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/dithering.glsl"
#include "/include/utility/text_rendering.glsl"

#ifdef DISTANCE_VIEW
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec2 taa_offset;

uniform float near;
uniform float far;

#include "/include/misc/lod_mod_support.glsl"
#include "/include/utility/space_conversion.glsl"
#endif

// ============================================================================
// BODYCAM SETTINGS
// ============================================================================

#define BODYCAM_ENABLED 0               // [0 1]
#define BODYCAMMISC_ENABLED 0          // Enable additional bodycam effects [0 1]

// Main bodycam parameters
#define DISTORTION_STRENGTH 0.9        // Fisheye distortion strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define HORIZONTAL_EDGE_STRENGTH 1.5    // Horizontal edge distortion strength [0.0 0.3 0.6 0.9 1.2 1.5]
#define VERTICAL_EDGE_STRENGTH 1.6      // Vertical edge distortion strength [0.0 0.4 0.8 1.2 1.6]
#define CORNER_DISTORT_STRENGTH 0.5     // Corner distortion strength [0.0 0.3 0.6 0.9 1.2 1.5]
#define CIRCULAR_DISTORT_STRENGTH 1.0   // Circular distortion strength [0.0 0.3 0.6 0.9 1.2 1.5]
#define ZOOM 0.8                        // Image zoom level [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define ZOOM_NEW 0.75                  // [0.75 0.80 0.825 0.85 0.90 0.95 1.00]
#define DIST_STRENGTH 1.00              // [-1.00 -0.85 -0.75 -0.65 -0.50 -0.45 -0.35 -0.25 -0.15 0.00 0.15 0.25 0.35 0.45 0.50 0.65 0.75 0.85 1.00 1.15 1.25 1.35 1.50]

#define INTENSITY_CAM_SHAKE 0.01        // Camera shake intensity [0.0 0.002 0.004 0.006 0.008 0.01]
#define INTENSITY_CAM_SHAKE_NEW 0.00    // [0.00 0.001 0.0025 0.005 0.01]
#define HAND_SWAY_STRENGTH 0.0         // Hand sway strength [0.0 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01]

// Chromatic aberration for bodycam
#define BODYCAM_CHROMA_STRENGTH 0.0011       // Сила хроматической аберрации в бодикаме [0.0000 0.0005 0.0008 0.0010 0.0011 0.0013 0.0015 0.0018 0.0020 0.0025 0.0030 0.0035 0.0040 0.0050 0.0060 0.0080 0.010 0.015 0.020 0.030]
#define BODYCAM_CHROMA_OPACITY 1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

// CRT and bloom
#define CRT_CURVE 0.05                 // CRT curvature strength [0.0 0.02 0.04 0.06 0.08 0.1]
#define BLOOM_ENABLED 0                // Enable bloom [0 1]
#define BLOOM_STRENGTH 0.1             // Bloom strength [0.0 0.05 0.1 0.15 0.2]

// Vignette
#define VIGNETTE 1                     // Enable vignette [0 1]
#define VIGNETTE_STRENGTH 0.78          // Main vignette strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VIGNETTE_RADIUS 0.001           // Main vignette radius [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define CORNER_VIGNETTE_STRENGTH 0.4    // Corner vignette strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VIGNETTE_RADIUS_NEW 0.45        // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define VIGNETTE_STRENGTH_NEW 0.90      // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define DYNAMIC_VIGNETTE 1             // Dynamic vignette [0 1]
#define DYNAMIC_VIGNETTE_STRENGTH 0.3  // Dynamic vignette strength [0.0 0.1 0.2 0.3 0.4 0.5]
#define DYNAMIC_VIGNETTE_SWAY 1        // Vignette sway with movement [0 1]
#define DYNAMIC_VIGNETTE_TILT 0.8      // Vignette tilt strength [0.0 0.2 0.4 0.6 0.8 1.0]
#define CUBIC_VIGNETTE_ENABLED 1       // Enable cubic vignette [0 1]
#define CUBIC_VIGNETTE_STRENGTH 0.5    // Cubic vignette strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Grain and noise
#define GRAIN 0                        // Enable grain [0 1]
#define NOISE_STRENGTH 0.00             // Noise strength for bodycam effect [0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define GRAIN_STRENGTH 0.05            // Grain strength [0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define DYNAMIC_NOISE 0                // Dynamic noise [0 1]
#define DYNAMIC_NOISE_STRENGTH 0.02    // Dynamic noise strength [0.0 0.01 0.02 0.03 0.04 0.05]

// Scanlines
#define SCANLINE 0                      // [0 1]
#define SCANLINE_STRENGTH 0.00          // Scanline effect strength [0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define SCANLINE_WIDTH 800.0            // Scanline density [500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0]
#define SCANLINE_STRENGTH_NEW 0.025     // [0.01 0.025 0.05 0.075 0.1]
#define SCANLINE_WIDTH_NEW 750          // [100 250 500 750 1000]

// PS1 style
#define PS1_STYLE_ENABLED 0            // Enable PS1 style [0 1]
#define PS1_STYLE_INTENSITY 0.5        // PS1 style intensity [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Color grading
#define BRIGHTNESS 0.0                  // Brightness adjustment [-0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5]
#define CONTRAST 1.0                    // Contrast adjustment [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

// NVG (Night Vision Goggles) when sneaking - DISABLED
#define ENABLE_NVG_IsSneaking 0        // Enable NVG on sneak [0 1]
#define NVG 0                           // [0 1]
#define NVG_R 0.0                      // Red component [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define NVG_G 1.0                      // Green component [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define NVG_B 0.0                      // Blue component [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define NVG_BRIGHTNESS 1.5             // NVG brightness multiplier [0.5 1.0 1.5 2.0 2.5 3.0]

// Black stripes/FOV mask
#define BLACK_STRIPES 1                // Enable black stripes [0 1]
#define BLACK_STRIPES_WIDTH 0.05        // Black stripes width [0.0 0.02 0.04 0.06 0.08 0.1]
#define BLACK_STRIPES_SOFT 0.05         // Black stripes edge softness [0.0 0.01 0.02 0.03 0.04 0.05]
#define BLACK_STRIPES_WIDTH_NEW 0.40    // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55]
#define BLACK_STRIPES_SOFT_NEW 1.00     // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define BLACK_FOV 70.0                  // Black FOV rounding field of view [1.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0]
#define BODYCAM_STYLE 0                // FOV style: 0=round, 1=square [0 1]

// Sharpening
#define SHARPNESS_STRENGTH 0.5         // Sharpness strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Image rounding and distortion
#define IMAGE_ROUNDING_RADIUS 5.0       // Image rounding distortion radius [0.1 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.3]
#define IMAGE_VERTICAL_STRENGTH 0.2     // Vertical image rounding strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define IMAGE_HORIZONTAL_STRENGTH 0.2   // Horizontal image rounding strength [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define IMAGE_ROUND_STRENGTH 0.8        // Circular image mask strength [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

// Lens and motion blur
#define LENS_STRENGTH 0.2               // Lens effect strength [-0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define MOTION_BLUR_RADIUS 0.25         // Motion blur (Shake) radius [0.02 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define MOTION_BLUR_MOUSE_STRENGTH 1.02 // Motion blur (Mouse) strength [1.0 1.01 1.02 1.03 1.04 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define MOTION_BLURRING_STRENGTH 1.25   // [0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.0]

// Flicker and glitch
#define FLICKER_STRENGTH 0.02           // Brightness flicker strength [0.0 0.01 0.02 0.03 0.04 0.05]
#define GLITCH_STRENGTH 0.000           // Glitch distortion strength [0.0 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01]
#define ENABLE_HORIZONTAL_GLITCH 0      // Enable horizontal glitch effect [0 1]

// Lens flare
#define LENS_FLARE_STRENGTH 0.5         // Lens flare intensity [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LENS_FLARE_SCALE 1.3            // Lens flare size [0.1 0.2 0.3 0.4 0.5]
#define LENS_FLARE_STREAKS 5            // Number of flare streaks [2 3 4 5 6]

// VHS Settings
#define VHS_ENABLED 0                   // [0 1]
#define VHS_SHAKE 0.015                 // [0.0 0.005 0.01 0.015 0.02 0.025 0.03]
#define VHS_NOISE_INTENSITY 0.001       // [0.0 0.0005 0.001 0.0015 0.002 0.003]
#define VHS_OFFSET_INTENSITY 0.05       // [0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07]
#define VHS_COLOR_OFFSET_INTENSITY 0.2  // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VHS_NOISE_QUALITY 250.0         // [100.0 150.0 200.0 250.0 300.0 400.0]
#define VHS_STATIC_GLITCH_INTENSITY 0.3 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VHS_PURPLE_STATIC_ENABLED 1     // [0 1]
#define VHS_PURPLE_STATIC_INTENSITY 0.4 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Fisheye center strength (from first code)
#define FISHEYE_CENTER_STRENGTH 0.5    // Fisheye strength near center [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Additional settings for posterization
#define POSTERIZATION_ENABLED 0        // Enable posterization [0 1]
#define POSTERIZATION_LEVELS 8         // Number of color levels [4 8 16 32]

// Chromatic aberration styles
#define CHROMATIC_ABERRATION_ENABLED 0 // Enable chromatic aberration [0 1]
#define CHROMATIC_ABERRATION_STYLE 1   // Style: 1=Classic, 2=GoPro, 3=Rainbow, 4=Blue-Green [1 2 3 4]
#define CHROMATIC_ABERRATION_STRENGTH 0.003 // Strength [0.0 0.001 0.002 0.003 0.004 0.005]
#define CHROMATIC_ABERRATION_CENTER 0.5 // Center focus [0.0 0.3 0.5 0.7 1.0]

// Eye squint effect
#define EYE_SQUINT_ENABLED 0           // Enable eye squint [0 1]
#define EYE_SQUINT_HEIGHT_PIXELS 20.0  // Height in pixels [10.0 20.0 30.0 40.0 50.0]
#define EYE_SQUINT_SOFTNESS 5.0        // Softness [2.0 5.0 10.0 15.0]
#define EYE_SQUINT_OFFSET 0.0          // Offset [0.0 5.0 10.0 15.0]

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const int debug_text_scale = 2;
ivec2 debug_text_position = ivec2(0, int(viewHeight) / debug_text_scale);

#if DEBUG_VIEW == DEBUG_VIEW_WEATHER
#include "/include/misc/debug_weather.glsl"
#endif

vec3 min_of(vec3 a, vec3 b, vec3 c, vec3 d, vec3 f) {
    return min(a, min(b, min(c, min(d, f))));
}

vec3 max_of(vec3 a, vec3 b, vec3 c, vec3 d, vec3 f) {
    return max(a, max(b, max(c, max(d, f))));
}

// Random function
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Hash functions for VHS
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

vec2 hash2D(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Noise function for bodycam
float bodyCamNoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = random(i + vec2(0.0, 0.0));
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Camera shake
vec2 cameraShake(float frameTimeCounter, float intensity) {
    return vec2(
        intensity * sin(frameTimeCounter * 1.5),
        intensity * cos(frameTimeCounter * 1.85)
    );
}

// Hand sway
vec2 handSway(float frameTimeCounter, float intensity) {
    return vec2(
        intensity * sin(frameTimeCounter * 2.0),
        intensity * cos(frameTimeCounter * 2.5)
    );
}

// UV rotation
vec2 rotateUV(vec2 uv, float angle) {
    vec2 center = vec2(0.5, 0.5);
    vec2 d = uv - center;
    float c = cos(angle);
    float s = sin(angle);
    return center + vec2(
        d.x * c - d.y * s,
        d.x * s + d.y * c
    );
}

// CRT curve distortion
vec2 applyCRTCurve(vec2 coord) {
    vec2 centered = coord - 0.5;
    float dist = length(centered);
    float curve = dist * CRT_CURVE;
    centered *= (1.0 + curve * dist);
    return centered + 0.5;
}

// Black FOV mask
float blackFOVMask(vec2 coord) {
    vec2 centered = abs(coord - 0.5);
    float fovScale = 1.0 / (0.01 + 0.99 * (BLACK_FOV / 100.0));
    #if BODYCAM_STYLE == 0
        float r = length(centered * fovScale); // Round style
        return 1.0 - smoothstep(0.7, 1.0, r);
    #else
        float r = max(centered.x, centered.y) * fovScale; // Square style
        return 1.0 - smoothstep(0.7, 1.0, r);
    #endif
}

// Bloom effect
vec3 applyBloom(vec2 coord, vec3 color) {
    #if BLOOM_ENABLED == 1
    vec3 bloom = vec3(0.0);
    const int samples = 5;
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    for (int i = -samples / 2; i <= samples / 2; i++) {
        for (int j = -samples / 2; j <= samples / 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * texelSize * 2.0;
            vec3 sampleColor = texture2D(colortex0, coord + offset).rgb;
            bloom += max(vec3(0.0), sampleColor - 0.5) * 0.05;
        }
    }
    bloom /= float(samples * samples);
    return color + bloom * BLOOM_STRENGTH;
    #else
    return color;
    #endif
}

// Dynamic vignette with sway
float applyDynamicVignette(vec2 coord, vec2 centered) {
    #if DYNAMIC_VIGNETTE == 0
        return 0.0;
    #endif
    
    float distance = length(centered);
    float baseVignette = smoothstep(VIGNETTE_RADIUS_NEW, VIGNETTE_RADIUS_NEW + VIGNETTE_STRENGTH_NEW, distance);
    
    #if DYNAMIC_VIGNETTE_SWAY == 1
        float cameraMotion = length(cameraSpeed.xz);
        float verticalMotion = abs(cameraSpeed.y);
        float totalMotion = cameraMotion + verticalMotion * 0.5;
        totalMotion = clamp(totalMotion * 0.1, 0.0, 1.0);
        
        // Direction of sway
        vec2 motionDir = normalize(vec2(cameraSpeed.x, -cameraSpeed.z) + vec2(0.001));
        float tiltEffect = dot(normalize(centered), motionDir);
        tiltEffect = tiltEffect * 0.5 + 0.5;
        
        // Asymmetric vignette
        float dynamicBoost = totalMotion * DYNAMIC_VIGNETTE_STRENGTH;
        float tiltBoost = tiltEffect * DYNAMIC_VIGNETTE_TILT * totalMotion;
        
        baseVignette += dynamicBoost * distance;
        baseVignette += tiltBoost * 0.3;
        
        // Pulsation
        float pulse = sin(frameTimeCounter * 10.0 * totalMotion) * 0.05 * totalMotion;
        baseVignette += pulse;
    #endif
    
    return clamp(baseVignette, 0.0, 1.0);
}

// Cubic vignette
float applyCubicVignette(vec2 coord) {
    #if CUBIC_VIGNETTE_ENABLED == 1
    vec2 centered = abs(coord - 0.5);
    float vertical = pow(centered.y, 3.0);
    float corner = length(centered) * 0.2;
    return clamp(vertical + corner, 0.0, 1.0) * CUBIC_VIGNETTE_STRENGTH;
    #else
    return 0.0;
    #endif
}

// PS1 style pixelation
vec3 applyPS1Style(vec2 coord, vec3 color) {
    #if PS1_STYLE_ENABLED == 1
    vec2 lowResCoord = floor(coord * vec2(viewWidth, viewHeight) / 4.0) * 4.0 / vec2(viewWidth, viewHeight);
    vec3 lowResColor = texture2D(colortex0, lowResCoord).rgb;
    float dither = bayer16(gl_FragCoord.xy) * 0.05 * PS1_STYLE_INTENSITY;
    return mix(color, lowResColor + dither, PS1_STYLE_INTENSITY);
    #else
    return color;
    #endif
}

// ============================================================================
// VHS EFFECTS
// ============================================================================

vec2 vhsDistortion(vec2 uv, float time) {
    float wave1 = sin(uv.y * 8.0 + time * 2.0) * 0.001;
    float wave2 = sin(uv.y * 15.0 + time * 3.5) * 0.001;
    float glitchLine = floor(uv.y * 200.0);
    float glitchRandom = hash(glitchLine + floor(time * 5.0));
    float glitchStrength = step(0.98, glitchRandom) * 0.02;
    float horizontalShift = glitchStrength * (hash(glitchLine * 13.7 + time) - 0.5);
    return uv + vec2(wave1 + wave2 + horizontalShift, 0.0);
}

vec3 chromaShift(sampler2D tex, vec2 uv, float time) {
    float shift = 0.002 + sin(time * 0.5) * 0.001;
    vec2 redUV = uv + vec2(shift, 0.0);
    vec2 greenUV = uv;
    vec2 blueUV = uv - vec2(shift, 0.0);
    float r = texture2D(tex, redUV).r;
    float g = texture2D(tex, greenUV).g;
    float b = texture2D(tex, blueUV).b;
    return vec3(r, g, b);
}

float scanlines(vec2 uv) {
    float line = sin(uv.y * viewHeight * 0.7) * 0.08;
    return 1.0 - abs(line);
}

float filmGrain(vec2 uv, float time) {
    vec2 grainUV = uv * 300.0 + time * 50.0;
    return (random(grainUV) - 0.5) * 0.25;
}

float trackingLines(vec2 uv, float time) {
    float tracking = 0.0;
    float speed = time * 0.1;
    float trackY = fract(speed) * 2.0 - 1.0;
    float trackDist = abs(uv.y - trackY);
    tracking += smoothstep(0.01, 0.0, trackDist) * 0.3;
    float track2Y = fract(speed * 0.7 + 0.3) * 2.0 - 1.0;
    float track2Dist = abs(uv.y - track2Y);
    tracking += smoothstep(0.005, 0.0, track2Dist) * 0.3;
    return tracking;
}

vec3 vhsColor(vec3 color, float time) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(gray), 0.3);
    color.r *= 1.1;
    color.g *= 0.95;
    color.b *= 0.9;
    color = (color - 0.5) * 1.3 + 0.6;
    color += vec3(0.05, 0.03, 0.0);
    return color;
}

vec3 glitchBlocks(vec3 color, vec2 uv, float time) {
    vec2 blockUV = floor(uv * vec2(20.0, 15.0));
    float blockRandom = hash(blockUV.x + blockUV.y * 13.7 + floor(time * 3.0));
    // Effects disabled but structure preserved
    return color;
}

vec3 vhs_effect(vec2 texcoord, vec3 base_color) {
    float time = frameTimeCounter;
    vec2 uv = texcoord;
    vec3 color = base_color;

    vec2 distortedUV = vhsDistortion(uv, time);
    color = chromaShift(colortex0, distortedUV, time);
    
    if (length(color) < 0.02) {
        color = texture2D(colortex0, uv).rgb;
    }
    
    color = glitchBlocks(color, uv, time);
    color *= scanlines(uv);
    color += filmGrain(uv, time);
    color += trackingLines(uv, time);
    color = vhsColor(color, time);
    
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.3;
    color *= vignette;
    color = clamp(color, 0.0, 1.0);

    return color;
}

// ============================================================================
// CHROMATIC ABERRATION STYLES
// ============================================================================

vec3 applyChromaticAberration(vec2 uv, vec3 color) {
    #if CHROMATIC_ABERRATION_ENABLED == 1
        vec2 coord = uv - 0.5;
        float dist = length(coord);
        float fovMask = mix(dist * 2.3, 1.0, CHROMATIC_ABERRATION_CENTER);
        float amount = CHROMATIC_ABERRATION_STRENGTH * fovMask;
        vec2 offset = coord * amount;

        #if CHROMATIC_ABERRATION_STYLE == 1          // Classic RGB
            color.r = texture2D(colortex0, uv + offset).r;
            color.g = texture2D(colortex0, uv).g;
            color.b = texture2D(colortex0, uv - offset).b;

        #elif CHROMATIC_ABERRATION_STYLE == 2        // GoPro style
            color.r = texture2D(colortex0, uv + offset * 1.7).r;
            color.g = texture2D(colortex0, uv - offset * 0.4).g;
            color.b = texture2D(colortex0, uv - offset * 0.7).b;

        #elif CHROMATIC_ABERRATION_STYLE == 3        // Rainbow dynamic
            float time = frameTimeCounter * 0.9;
            float hue = time * 0.3;
            vec3 rainbow = 0.5 + 0.5 * cos(hue + vec3(0.0, 2.094, 4.188));
            
            vec2 offsetR = offset * (0.8 + 0.6 * rainbow.r);
            vec2 offsetG = offset * (0.8 + 0.6 * rainbow.g);
            vec2 offsetB = offset * (0.8 + 0.6 * rainbow.b);

            color.r = texture2D(colortex0, uv + offsetR).r;
            color.g = texture2D(colortex0, uv + offsetG * vec2(1.0, -0.7)).g;
            color.b = texture2D(colortex0, uv - offsetB * vec2(0.8, 1.1)).b;

        #elif CHROMATIC_ABERRATION_STYLE == 4        // Blue-Green only
            color.r = texture2D(colortex0, uv).r;
            color.g = texture2D(colortex0, uv + offset * 0.9).g;
            color.b = texture2D(colortex0, uv - offset * 1.3).b;
        #endif
    #endif
    return color;
}

// ============================================================================
// EYE SQUINT EFFECT
// ============================================================================

vec3 applyEyeImitation(vec2 texcoord, vec3 color) {
    #if EYE_SQUINT_ENABLED == 1
    float px = 1.0 / viewHeight;
    float baseHeight = EYE_SQUINT_HEIGHT_PIXELS * px;
    float softUV = EYE_SQUINT_SOFTNESS * px;

    float target = float(isSneaking);
    float h = baseHeight * target;
    float offset = 15.0 * px * target + EYE_SQUINT_OFFSET;

    // Top bar
    float topLow = 1.0 - h - offset;
    float topHigh = topLow + softUV;
    float topMask = smoothstep(topLow, topHigh, texcoord.y);

    // Bottom bar
    float bottomHigh = h + offset;
    float bottomLow = bottomHigh - softUV;
    float bottomMask = 1.0 - smoothstep(bottomLow, bottomHigh, texcoord.y);

    float mask = max(topMask, bottomMask);
    color = mix(color, vec3(0.0), mask);
    #endif
    return color;
}

// ============================================================================
// BODYCAM MAIN EFFECT
// ============================================================================

vec3 applyBodycamEffects(vec2 texcoord, vec3 base_color) {
    vec3 color = base_color;
    vec2 uv = texcoord;

    #if BODYCAMMISC_ENABLED == 1 || BODYCAM_ENABLED == 1
    vec2 centered = (texcoord - 0.5) * ZOOM_NEW + 0.5;
    float distance = length(centered - 0.5);

    #if BODYCAMMISC_ENABLED == 1
    vec2 crtUV = applyCRTCurve(centered);
    #else
    vec2 crtUV = centered;
    #endif

    vec2 shake = cameraShake(frameTimeCounter, INTENSITY_CAM_SHAKE_NEW) + handSway(frameTimeCounter, HAND_SWAY_STRENGTH);
    vec2 rotatedUV = rotateUV(crtUV + shake, sin(frameTimeCounter * 0.5) * 0.02);

    #if BODYCAM_ENABLED == 1
    float center_factor = pow(distance, 2.0) * FISHEYE_CENTER_STRENGTH;
    vec2 fisheyeUV = (rotatedUV - 0.5) * (1.0 + DIST_STRENGTH * (distance * distance + center_factor)) + 0.5;
    #else
    vec2 fisheyeUV = rotatedUV;
    #endif

    #if BODYCAM_ENABLED == 1
    // Chromatic aberration - simple RGB channel separation
    color.r = texture2D(colortex0, fisheyeUV + vec2(BODYCAM_CHROMA_STRENGTH * distance)).r;
    color.g = texture2D(colortex0, fisheyeUV).g;
    color.b = texture2D(colortex0, fisheyeUV - vec2(BODYCAM_CHROMA_STRENGTH * distance)).b;
    #else
    color = texture2D(colortex0, fisheyeUV).rgb;
    #endif

    #if BODYCAMMISC_ENABLED == 1
    // Manual sharpening
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec3 sharpenedColor = vec3(0.0);
    sharpenedColor += texture2D(colortex0, fisheyeUV + texelSize * vec2(-1.0, 0.0)).rgb * -0.25;
    sharpenedColor += texture2D(colortex0, fisheyeUV + texelSize * vec2(1.0, 0.0)).rgb * -0.25;
    sharpenedColor += texture2D(colortex0, fisheyeUV + texelSize * vec2(0.0, -1.0)).rgb * -0.25;
    sharpenedColor += texture2D(colortex0, fisheyeUV + texelSize * vec2(0.0, 1.0)).rgb * -0.25;
    sharpenedColor += texture2D(colortex0, fisheyeUV).rgb * 2.0;
    color = mix(color, sharpenedColor, SHARPNESS_STRENGTH);
    #endif

    color = clamp(color, 0.0, 1.0);

    #if BODYCAMMISC_ENABLED == 1
    color = applyBloom(fisheyeUV, color);
    #endif

    #if BODYCAMMISC_ENABLED == 1
    color = applyPS1Style(fisheyeUV, color);
    #endif

    #if SCANLINE == 1
    float scanline = sin(fisheyeUV.y * SCANLINE_WIDTH_NEW * 1.5) * SCANLINE_STRENGTH_NEW;
    color += scanline;
    #endif

    #if GRAIN == 1
    float noise = (bodyCamNoise(fisheyeUV + vec2(frameTimeCounter)) - 0.5) * GRAIN_STRENGTH;
    #if DYNAMIC_NOISE == 1 && BODYCAMMISC_ENABLED == 1
    noise *= (1.0 + DYNAMIC_NOISE_STRENGTH * (isSneaking + sin(frameTimeCounter * 2.0)));
    #endif
    color += vec3(noise);
    #endif

    #if ENABLE_NVG_IsSneaking == 1
    if (isSneaking == 1.0) {
        float gray = dot(color, vec3(0.299, 0.587, 0.114));
        vec3 grayscale = vec3(gray);
        vec3 colorTransform = vec3(NVG_R, NVG_G, NVG_B) * NVG_BRIGHTNESS;
        color = grayscale * colorTransform;
    }
    #endif

    #if VIGNETTE == 1
    vec2 centeredVig = texcoord - 0.5;
    float vignetteEffect = applyDynamicVignette(texcoord, centeredVig);
    color = mix(color, vec3(0.0), vignetteEffect);
    #endif

    #if BODYCAMMISC_ENABLED == 1
    float cubicVignette = applyCubicVignette(texcoord);
    color = mix(color, vec3(0.0), cubicVignette);
    #endif

    #if BLACK_STRIPES == 1
    float leftStripe = smoothstep(BLACK_STRIPES_WIDTH_NEW, BLACK_STRIPES_WIDTH_NEW - BLACK_STRIPES_SOFT_NEW, texcoord.x);
    float rightStripe = smoothstep(1.0 - BLACK_STRIPES_WIDTH_NEW, 1.0 - (BLACK_STRIPES_WIDTH_NEW - BLACK_STRIPES_SOFT_NEW), texcoord.x);
    float stripeEffect = max(leftStripe, rightStripe);
    color = mix(color, vec3(0.0), stripeEffect);
    #endif

    float fov_mask = blackFOVMask(texcoord);
    color = mix(color, vec3(0.0), 1.0 - fov_mask);
    #endif

    return color;
}

// ============================================================================
// IRIS REQUIRED ERROR
// ============================================================================

void draw_iris_required_error_message() {
    fragment_color = vec3(
        sqr(sin(uv.xy + vec2(0.4, 0.2) * frameTimeCounter)) * 0.5 + 0.3,
        1.0
    );
    begin_text(ivec2(gl_FragCoord.xy) / 3, ivec2(0, viewHeight / 3));
    text.fg_col = vec4(0.0, 0.0, 0.0, 1.0);
    text.bg_col = vec4(0.0);
    print((
        _I,
        _r,
        _i,
        _s,
        _space,
        _i,
        _s,
        _space,
        _r,
        _e,
        _q,
        _u,
        _i,
        _r,
        _e,
        _d,
        _space,
        _f,
        _o,
        _r,
        _space,
        _f,
        _e,
        _a,
        _t,
        _u,
        _r,
        _e,
        _space,
        _quote,
        _C,
        _o,
        _l,
        _o,
        _r,
        _e,
        _d,
        _space,
        _L,
        _i,
        _g,
        _h,
        _t,
        _s,
        _quote
    ));
    print_line();
    print_line();
    print_line();
    print((_H, _o, _w, _space, _t, _o, _space, _f, _i, _x, _colon));
    print_line();
    print((
        _space,
        _space,
        _minus,
        _space,
        _D,
        _i,
        _s,
        _a,
        _b,
        _l,
        _e,
        _space,
        _C,
        _o,
        _l,
        _o,
        _r,
        _e,
        _d,
        _space,
        _L,
        _i,
        _g,
        _h,
        _t,
        _s,
        _space,
        _i,
        _n,
        _space,
        _t,
        _h,
        _e,
        _space,
        _L,
        _i,
        _g,
        _h,
        _t,
        _i,
        _n,
        _g,
        _space,
        _m,
        _e,
        _n,
        _u
    ));
    print_line();
    print(
        (_space,
         _space,
         _minus,
         _space,
         _I,
         _n,
         _s,
         _t,
         _a,
         _l,
         _l,
         _space,
         _I,
         _r,
         _i,
         _s,
         _space,
         _1,
         _dot,
         _6,
         _space,
         _o,
         _r,
         _space,
         _a,
         _b,
         _o,
         _v,
         _e)
    );
    print_line();
    end_text(fragment_color);
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
#if defined COLORED_LIGHTS && !defined IS_IRIS
    draw_iris_required_error_message();
    return;
#endif

    ivec2 texel = ivec2(gl_FragCoord.xy);

    if (abs(MC_RENDER_QUALITY - 1.0) < 0.01)  {
        fragment_color = catmull_rom_filter_fast_rgb(colortex0, uv, 0.6);
        fragment_color = display_eotf(fragment_color);
    }

    // Apply VHS effects first if enabled
    #if VHS_ENABLED == 1
    fragment_color = vhs_effect(uv, fragment_color);
    #endif

    // Apply bodycam effects
    #if BODYCAM_ENABLED == 1 || BODYCAMMISC_ENABLED == 1
    fragment_color = applyBodycamEffects(uv, fragment_color);
    #endif

    // Apply chromatic aberration styles
    fragment_color = applyChromaticAberration(uv, fragment_color);

    // Posterization
    #if POSTERIZATION_ENABLED == 1
    float levels = float(POSTERIZATION_LEVELS);
    fragment_color.rgb = floor(fragment_color.rgb * levels) / levels;
    #endif

    // Apply eye squint effect
    fragment_color = applyEyeImitation(uv, fragment_color);

    fragment_color = dither_8bit(fragment_color, bayer16(vec2(texel)));

#if DEBUG_VIEW == DEBUG_VIEW_SAMPLER
    if (clamp(texel, ivec2(0), ivec2(textureSize(DEBUG_SAMPLER, 0))) == texel) {
        fragment_color = texelFetch(DEBUG_SAMPLER, texel, 0).rgb;
        fragment_color = display_eotf(fragment_color);
    }
#elif DEBUG_VIEW == DEBUG_VIEW_WEATHER
    debug_weather(fragment_color);
#endif

#ifdef DISTANCE_VIEW
    float depth = texelFetch(depthtex0, ivec2(uv * view_res * taau_render_scale), 0).x;

    vec3 position_screen = vec3(uv, depth);
    vec3 position_view = screen_to_view_space(gbufferProjectionInverse, position_screen, true);

    bool is_sky = depth == 1.0;

#ifdef LOD_MOD_ACTIVE
    float depth_lod = texelFetch(lod_depth_tex, texel, 0).x;
    bool is_lod = is_lod_terrain(depth, depth_lod);

    if (is_lod) {
        position_view = screen_to_view_space(
            dhProjectionInverse,
            vec3(uv, depth_lod),
            true
        );
    }

    is_sky = is_sky && depth_lod == 1.0;
#endif

#if DISTANCE_VIEW_METHOD == DISTANCE_VIEW_DISTANCE
    float dist = length(position_view);
#elif DISTANCE_VIEW_METHOD == DISTANCE_VIEW_DEPTH
    float dist = -position_view.z;
#endif

    fragment_color = is_sky
        ? vec3(1.0)
        : vec3(clamp01(dist * rcp(DISTANCE_VIEW_MAX_DISTANCE)));
#endif

#if defined COLORED_LIGHTS && (defined WORLD_NETHER || !defined SHADOW)
    // Must sample shadowtex0 so that the shadow map is rendered
    if (uv.x < 0.0) {
        fragment_color = texture(shadowtex0, uv).rgb;
    }
#endif
}

#include "/include/buffers.glsl"
