#version 300 es

precision highp float;

#define TAU 6.28318530718f
#define EPSILON 1e-6f
#define BIAS 1e-4f

#define N 128
#define MAX_STEP 64
#define MAX_DISTANCE 5.0

#include sdf.glsl
#include shape.glsl

uniform vec2 resolution;

out vec4 fragColor;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 beerLambert(vec3 a, float d) {
    return exp(-a * d);
}

Shape scene(vec2 p) {
    Shape r1 = Shape(
        circleSDF(p, vec2(0.5, 0.5), 0.3),
        0.0,
        1.5,
        vec3(0.6, 0.6, 0.3),
        vec3(0.0)
    );
    Shape r2 = Shape(
        circleSDF(p, vec2(0.7, 0.5), 0.3),
        0.0,
        0.0,
        vec3(0.0),
        vec3(0.0)
    );
    Shape r3 = Shape(
        circleSDF(p, vec2(0.8, 0.5), 0.15),
        1.0,
        0.0,
        vec3(0.4, 0.4, 0.2),
        vec3(0.0)
    );
    return unionOP(r3, subtractOP(r1, r2));
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
        float a = TAU * (float(i) + random(p)) / float(N);
        vec2 incident = vec2(cos(a), sin(a));
        sum += trace(p, incident);
    }
    return sum / float(N);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec3 color = render(uv);
    fragColor = vec4(color, 1.0);
}
