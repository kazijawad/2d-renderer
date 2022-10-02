#version 300 es

#define TWO_PI 6.28318530718f
#define EPSILON 1e-6f
#define BIAS 1e-4f

#define W 512
#define H 512
#define N 128

#define MAX_STEP 64
#define MAX_DISTANCE 5.0

precision highp float;

uniform vec2 resolution;

out vec4 fragColor;

struct Shape {
    float sd;
    float reflectivity;
    float eta;
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

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

float planeSDF(vec2 p, vec2 c, vec2 n) {
    return dot(p - c, n);
}

float circleSDF(vec2 p, vec2 c, float r) {
    return length(p - c) - r;
}

float boxSDF(vec2 p, vec2 c, vec2 b) {
    vec2 d = abs(p - c) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
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

Shape scene(vec2 p) {
    Shape r1 = Shape(
        circleSDF(p, vec2(0.3, 0.75), 0.2),
        0.5,
        0.0,
        vec3(1.0),
        vec3(0.0)
    );
    Shape r2 = Shape(
        circleSDF(p, vec2(0.75, 0.7), 0.1),
        0.5,
        0.0,
        vec3(1.0),
        vec3(0.0)
    );
    Shape r3 = Shape(
        boxSDF(p, vec2(0.5, 0.3), vec2(0.4, 0.2)),
        0.0,
        1.0,
        vec3(0.0),
        vec3(1.0)
    );
    return unionOP(unionOP(r1, r2), r3);
}

vec2 gradient(vec2 q) {
    vec2 grad = vec2(0.0);
    grad.x = (scene(vec2(q.x + EPSILON, q.y)).sd - scene(vec2(q.x - EPSILON, q.y)).sd) * (0.5 / EPSILON);
    grad.y = (scene(vec2(q.x, q.y + EPSILON)).sd - scene(vec2(q.x, q.y - EPSILON)).sd) * (0.5 / EPSILON);
    return grad;
}

vec3 traceRef(vec2 p, vec2 incident) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEP && t < MAX_DISTANCE; i++) {
        vec2 q = p + incident * t;
        Shape r = scene(q);
        if (r.sd < EPSILON) {
            return r.emissive * beerLambert(r.absorption, t);
        }
        t += r.sd;
    }
    return vec3(0.0);
}

vec3 trace(vec2 p, vec2 incident) {
    float t = 1e-3;
    float multiplier = sign(scene(p).sd);
    for (int i = 0; i < MAX_STEP && t < MAX_DISTANCE; i++) {
        vec2 q = p + incident * t;
        Shape r = scene(q);
        if (r.sd * multiplier < EPSILON) {
            vec3 sum = r.emissive;
            if (r.reflectivity > 0.0 || r.eta > 0.0) {
                vec2 normal = gradient(q);
                normal *= multiplier;
                if (r.eta > 0.0) {
                    vec2 refraction;
                    if (multiplier < 0.0) {
                        refraction = refract(incident, normal, r.eta);
                    } else {
                        refraction = refract(incident, normal, 1.0 / r.eta);
                    }
                    if (refraction.x > 0.0 && refraction.y > 0.0) {
                        sum += (1.0 - r.reflectivity) * traceRef(q - normal * BIAS, refraction);
                    } else {
                        r.reflectivity = 1.0;
                    }
                }
                if (r.reflectivity > 0.0) {
                    vec2 reflection = reflect(incident, normal);
                    sum += r.reflectivity * traceRef(q + normal * BIAS, reflection);
                }
            }
            return sum * beerLambert(r.absorption, t);
        }
        t += r.sd * multiplier;
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
    vec2 uv = gl_FragCoord.xy / resolution;
    vec3 c = render(uv);
    fragColor = vec4(c, 1.0);
}
