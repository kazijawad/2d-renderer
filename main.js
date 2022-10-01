import './styles.css';
import { Renderer, Program, Texture } from 'gl-layer';
import frag from './frag.glsl';

const W = 1000;
const H = 1000;
const N = 32;

const MAX_STEP = 10;
const MAX_DISTANCE = 2;

const renderer = new Renderer();
const gl = renderer.gl;

init();
addEventHandlers();

function init() {
    handleResize();
    render();
}

function addEventHandlers() {
    window.addEventListener('resize', handleResize);
}

function handleResize() {
    renderer.setSize(W, H);
}

function union(a, b) {
    return a.sd < b.sd ? a : b;
}

function intersect(a, b) {
    const r = a.sd > b.sd ? b : a;
    r.sd = a.sd > b.sd ? a.sd: b.sd;
    return r;
}

function subtract(a, b) {
    const r = a;
    r.sd = (a.sd > -b.sd) ? a.sd : -b.sd;
    return r;
}

function length(x, y) {
    return Math.sqrt(x * x + y * y);
}

function clamp(x, min, max) {
    return Math.min(Math.max(x, min), max);
}

function dot(a, b) {
    return a.map((_, i) => a[i] * b[i]).reduce((m, n) => m + n);
}

function circleSDF(x, y, cx, cy, r) {
    return length(x - cx, y - cy) - r;
}

function octagonSDF(x, y, cx, cy, r) {
    const k = [-0.9238795325, 0.3826834323, 0.4142135623];
    const p = [Math.abs(x - cx), Math.abs(y - cy)];

    let kdotp = Math.min(dot([k[0], k[1]], p), 0);
    p[0] -= 2.0 * kdotp * k[0];
    p[1] -= 2.0 * kdotp * k[1];

    kdotp = Math.min(dot([-k[0], k[1]], p), 0);
    p[0] -= 2.0 * kdotp * -k[0];
    p[1] -= 2.0 * kdotp * k[1];

    p[0] -= clamp(p[0], -k[2] * r, k[2] * r);
    p[1] -= r;

    return length(...p) * Math.sign(p[1]);
}

function scene(x, y) {
    const r1 = { sd: circleSDF(x, y, 0.2, 0.3, 0.1), emissive: 1 };
    const r2 = { sd: octagonSDF(x, y, 0.6, 0.5, 0.2), emissive: 1 };

    return union(r1, r2);
}

function render() {
    const program = new Program(frag);

    let C = new Uint8Array(W * H);
    for (let y = 0; y < H; y++) {
        for (let x = 0; x < W; x++) {
            const s = sample(x / renderer.width, y / renderer.height) * 255;
            C[y * W + x] = Math.min(s, 255);
        }
    }

    const map = new Texture(C, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE);
    map.internalFormat = gl.R8;
    map.format = gl.RED;
    map.width = W;
    map.height = H;
    program.setUniform('map', map);

    renderer.render(program);
}

function sample(x, y) {
    let sum = 0;
    for (let i = 0; i < N; i++) {
        const a = 2 * Math.PI * (i + Math.random()) / N;
        sum += trace(x, y, Math.cos(a), Math.sin(a));
    }
    return sum / N;
}

function trace(x, y, dx, dy) {
    let t = 0;
    for (let i = 0; i < MAX_STEP && t < MAX_DISTANCE; i++) {
        const r = scene(x + dx * t, y + dy * t);
        if (r.sd < Number.EPSILON) {
            return r.emissive;
        }
        t += r.sd;
    }
    return 0;
}
