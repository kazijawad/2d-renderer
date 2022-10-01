#version 300 es

#define TWO_PI 6.28318530718f
#define EPSILON 1e-6f

#define W 1000
#define H 1000
#define N 64

#define MAX_STEP 10
#define MAX_DISTANCE 2.0

precision highp float;

uniform vec2 resolution;
uniform float uTime;

out vec4 fragColor;

struct Shape {
    float sd;
    vec3 emissive;
    vec3 absorption;
};

Shape unionOP(Shape a, Shape b) {
    if (a.sd < b.sd) {
        return a;
    }
    return b;
}

Shape intersectOP(Shape a, Shape b) {
    Shape r;
    if (a.sd > b.sd) {
        r = b;
        r.sd = a.sd;
    } else {
        r = a;
        r.sd = b.sd;
    }
    return r;
}

Shape subtractOP(Shape a, Shape b) {
    Shape r = a;
    if (a.sd > -b.sd) {
        r.sd = a.sd;
    } else {
        r.sd = -b.sd;
    }
    return r;
}

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float circleSDF(vec2 p, vec2 c, float r) {
    return length(p - c) - r;
}

float octagonSDF(vec2 p, vec2 c, float r) {
    const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623);
    p = abs(p - c);
    p -= 2.0 * min(dot(vec2(k.x,k.y), p), 0.0) * vec2(k.x,k.y);
    p -= 2.0 * min(dot(vec2(-k.x,k.y), p), 0.0) * vec2(-k.x,k.y);
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

vec3 beerLambert(vec3 a, float d) {
    return exp(-a * d);
}

vec2 rotatePosition() {
    float x = ((cos(uTime) + 1.0) * 0.25) + 0.25;
    float y = ((sin(uTime) + 1.0) * 0.25) + 0.25;
    return vec2(x, y);
}

Shape scene(float x, float y) {
    Shape r1 = Shape(circleSDF(vec2(x, y), rotatePosition(), 0.1), vec3(0.0, 0.5, 0.8), vec3(0.0));
    Shape r2 = Shape(circleSDF(vec2(x, y), vec2(0.5, 0.5), 0.1), vec3(0.0, 0.5, 0.8), vec3(0.0));
    return unionOP(r1, r2);
}

vec3 trace(vec2 p, vec2 incident) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEP && t < MAX_DISTANCE; i++) {
        vec2 q = p + incident * t;
        Shape r = scene(q.x, q.y);
        if (r.sd < EPSILON) {
            return r.emissive * beerLambert(r.absorption, t);
        }
        t += r.sd;
    }
    return vec3(0.0);
}

vec3 render(vec2 p) {
    vec3 sum = vec3(0.0);
    for (int i = 0; i < N; i++) {
        float a = TWO_PI * (float(i) + random(p)) / float(N);
        vec2 incident = vec2(cos(a), sin(a));
        sum += trace(p, incident);
    }
    return sum / float(N);
}

void main() {
    vec2 st = gl_FragCoord.xy / resolution;
    vec3 col = render(st);
    fragColor = vec4(col, 1.0);
}
