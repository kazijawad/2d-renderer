#version 300 es

precision highp float;

uniform vec2 resolution;
uniform sampler2D map;

out vec4 fragColor;

void main() {
    vec2 st = gl_FragCoord.xy / resolution;
    float col = texture(map, st).r;
    fragColor = vec4(vec3(col), 1);
}
