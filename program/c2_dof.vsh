#include "/include/global.glsl"
out vec2 uv;
void main() {
    uv = gl_MultiTexCoord0.xy;
    vec2 vertex_pos = gl_Vertex.xy;
    gl_Position = vec4(vertex_pos * 2.0 - 1.0, 0.0, 1.0);
}