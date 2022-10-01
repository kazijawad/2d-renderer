#version 300 es

#define TWO_PI 6.28318530718f
#define EPSILON 1e-6f
#define BIAS 1e-4f

#define W 1000
#define H 1000
#define N 128

#define MAX_STEP 10
#define MAX_DISTANCE 2.0
#define MAX_DEPTH 5

precision highp float;

uniform vec2 resolution;

out vec4 fragColor;

struct Shape {
    float sd;
    float emissive;
    float reflectance;
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

Shape scene(float x, float y) {
    Shape r1 = Shape(circleSDF(vec2(x, y), vec2(0.2, 0.5), 0.1), 1.0, 0.5);
    Shape r2 = Shape(octagonSDF(vec2(x, y), vec2(0.6, 0.5), 0.2), 1.0, 0.5);
    return unionOP(r1, r2);
}

vec2 gradient(float x, float y) {
    vec2 normal = vec2(0.0);
    normal.x = (scene(x + EPSILON, y).sd - scene(x - EPSILON, y).sd) * (0.5 / EPSILON);
    normal.y = (scene(x, y + EPSILON).sd - scene(x, y - EPSILON).sd) * (0.5 / EPSILON);
    return normal;
}

float trace(vec2 p, vec2 incident, int depth) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEP && t < MAX_DISTANCE; i++) {
        float x = p.x + incident.x * t;
        float y = p.y + incident.y * t;
        Shape r = scene(x, y);
        if (r.sd < EPSILON) {
            float sum = r.emissive;
            if (depth < MAX_DEPTH && r.reflectance > 0.0f) {
                vec2 normal = gradient(x, y);
                vec2 reflection = reflect(incident, normal);
                sum += r.reflectance * trace(x + normal * BIAS, reflection, depth + 1);
            }
            return r.emissive;
        }
        t += r.sd;
    }
    return 0.0;
}

float sampleXY(vec2 p) {
    float sum = 0.0;
    for (int i = 0; i < N; i++) {
        float a = TWO_PI * (float(i) + random(p)) / float(N);
        vec2 incident = vec2(cos(a), sin(a));
        sum += trace(p, incident, 0);
    }
    return sum / float(N);
}

void main() {
    vec2 st = gl_FragCoord.xy / resolution;
    float col = sampleXY(st);
    fragColor = vec4(vec3(col), 1.0);
}
